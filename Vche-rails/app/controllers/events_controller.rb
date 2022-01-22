class EventsController < ApplicationController::Bootstrap
  skip_before_action :require_login, only: [:index, :show, :appeal]

  def index
    @form = CalendarPresenterForm.new(Event.public_or_over, index_params, filter: { trust: :all }, paginate: true)
    @events = @form.events.includes(:event_schedules, :event_histories)
    authorize!
  end

  def show
    @event = find_event
    authorize! @event

    @user = current_user
    @form = CalendarPresenterForm.new([@event], show_params)
    @calendar = @form.presenter(current_user: @user, display_user: current_user, months: 2, candidate: true, offline: false)
  end

  def info
    @event = find_event
    @user = current_user
    authorize! @event
  end

  def select
    authorize!
  end

  def new
    @event = Event.new(capacity: 0)
    @role = new_params[:role] == 'owner' ? :owner : :participant
    authorize! @event

    if @role == :owner
      @event.name = new_params[:name]
      @event.hashtag = new_params[:hashtag]
      @event.organizer_name = current_user.display_name
      @event.primary_sns = "https://twitter.com/#{current_user.email}"
      @event.info_url = "https://twitter.com/#{current_user.email}"
      @event.visibility = :shared
    end
  end

  def edit
    @event = find_event
    authorize! @event
  end

  def create
    @event = Event.new(create_params)
    @event.created_user = current_user
    @event.updated_user = current_user
    role = params[:role] == 'owner' ? :owner : :participant
    authorize! @event

    if @event.save
      @event.flavors = event_flavors_params
      @event.event_follows.create(user: current_user, role: role)
      redirect_to @event, notice: I18n.t('notice.events.create.success')
    else
      render :new
    end
  end

  def update
    @event = find_event
    authorize! @event
    @event.updated_user = current_user

    if @event.update(**update_params, flavors: event_flavors_params)
      redirect_to @event, notice: I18n.t('notice.events.update.success')
    else
      render :edit
    end
  end

  def destroy
    @event = find_event
    authorize! @event

    Operations::Event::Destroy.new(event: @event, user: current_user).perform!
    render :destroyed
  end

  def follow
    @event = find_event
    authorize! @event

    Operations::Event::UpdateUserFollow.new(event: @event, user: current_user, role: params[:role] || @event.default_audience_role).perform!
    redirect_to @event, notice: I18n.t('notice.events.follow.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to @event
  rescue Operations::Event::UpdateUserFollow::UserIsBackstage
    redirect_to @event
  end

  def unfollow
    @event = find_event
    authorize! @event

    Operations::Event::UpdateUserFollow.new(event: @event, user: current_user, role: nil).perform!
    redirect_to @event, notice: I18n.t('notice.events.unfollow.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to @event
  rescue Operations::Event::UpdateUserFollow::UserIsBackstage
    redirect_to @event
  end

  def add_user
    @event = find_event
    authorize! @event
    @user = find_user

    Operations::Event::RequestUpdateUserRole.new(
      event: @event, creator: current_user, user: @user, approver: @user, role: params[:role]
    ).perform!
    redirect_to event_event_follows_url(@event), notice: I18n.t('notice.events.add_user.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_follows_url(@event)
  rescue Operations::Event::RequestUpdateUserRole::UserIsOwner
    redirect_to edit_event_owner_url(@event)
  end

  def change_user
    @event = find_event
    authorize! @event
    @user = find_user

    Operations::Event::UpdateUserRole.new(event: @event, user: @user, role: params[:role]).perform!
    redirect_to event_event_follows_url(@event), notice: I18n.t('notice.events.change_user.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_follows_url(@event)
  rescue Operations::Event::UpdateUserRole::UserIsOwner
    redirect_to edit_event_owner_url(@event)
  end

  def remove_user
    @event = find_event
    authorize! @event
    @user = find_user

    Operations::Event::UpdateUserRole.new(event: @event, user: @user, role: nil).perform!
    redirect_to event_event_follows_url(@event), notice: I18n.t('notice.events.remove_user.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_follows_url(@event)
  rescue Operations::Event::UpdateUserRole::UserIsOwner
    redirect_to edit_event_owner_url(@event)
  end

  def appeal
    @event = find_event
    authorize! @event
    redirect_to helpers.intent_url_for_event(@event)
  end

  private

  def find_user
    User.friendly.secret_or_over.find(params[:user_id])
  end

  def find_event
    Event.friendly.secret_or_over.find(params[:id])
  end

  def index_params
    params.permit(:category, :trust, :taste)
  end

  def show_params
    params.permit(:calendar, :date)
  end

  def new_params
    @new_params ||= params.permit(:role, :name, :hashtag)
  end

  def create_params
    params.require(:event).permit(
      :name, :fullname,
      :description, :organizer_name, :primary_sns_url, :info_url,
      :hashtag, :platform_id, :category_id, :visibility,
      :capacity, :multiplicity, :default_audience_role
    )
  end

  def update_params
    params.require(:event).permit(
      :name, :fullname,
      :description, :organizer_name, :primary_sns_url, :info_url,
      :hashtag, :platform_id, :category_id,
      :capacity, :multiplicity, :default_audience_role
    )
  end

  def event_flavors_params
    params['event_flavors'] || []
  end
end
