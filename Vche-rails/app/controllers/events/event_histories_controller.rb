class Events::EventHistoriesController < ApplicationController::Bootstrap
  before_action :find_parent_event
  skip_before_action :require_login, only: [:index, :show, :appeal]

  def index
    @event_histories = @event.event_histories.order(started_at: :desc).page(params[:page])
    @user = current_user
    authorize! @event
  end

  def show
    @event_history = find_event_history
    authorize! @event_history
    @user = current_user
  end

  def info
    @event_history = find_event_history
    authorize! @event_history
    @user = current_user
  end

  def at
    started_at = Time.zone.parse(params[:datetime])
    @event_history = @event.recent_histories([started_at.beginning_of_day]).detect { |h| h.started_at = started_at }
    authorize! @event_history
    render :show
  end

  def new
    authorize! @event
    @event_history = @event.event_histories.build
  end

  def edit
    @event_history = find_event_history
    authorize! @event_history
  end

  def create
    @event_history = @event.event_histories.build(create_params)
    authorize! @event_history
    @event_history.created_user = current_user
    @event_history.updated_user = current_user

    if @event_history.save
      redirect_to event_event_history_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.create.success')
    else
      render :new
    end
  end

  def update
    @event_history = find_event_history
    authorize! @event_history
    @event_history.updated_user = current_user
    if @event_history.update(update_params)
      redirect_to event_event_history_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.update.success')
    else
      render :edit
    end
  end

  def destroy
    @event_history = find_event_history
    authorize! @event_history
    @event_history.destroy
    redirect_to event_event_history_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.destroy.success')
  end

  def attend
    @event_history = find_event_history
    authorize! @event_history

    role = current_user.following_event?(@event) || @event_history.default_audience_role
    Operations::EventHistory::UpdateUserAttendance.new(event_history: @event_history, user: current_user, role: role).perform!
    redirect_to event_event_history_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.attend.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_history_path(@event, @event_history)
  rescue Operations::EventHistory::UpdateUserAttendance::UserIsAudience
    redirect_to event_event_history_path(@event, @event_history)
  end

  def unattend
    @event_history = find_event_history
    authorize! @event_history

    Operations::EventHistory::UpdateUserAttendance.new(event_history: @event_history, user: current_user, role: nil).perform!
    redirect_to event_event_history_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.unattend.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_history_path(@event, @event_history)
  rescue Operations::EventHistory::UpdateUserAttendance::UserIsAudience
    redirect_to event_event_history_path(@event, @event_history)
  end

  def add_user
    @event_history = find_event_history
    authorize! @event_history
    @user = find_user

    Operations::EventHistory::RequestUpdateUserRole.new(
      event_history: @event_history, creator: current_user, user: @user, approver: @user, role: params[:role]
    ).perform!
    redirect_to event_event_history_event_attendances_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.add_user.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_history_event_attendances_path(@event, @event_history)
  rescue Operations::EventHistory::RequestUpdateUserRole::Outsider
    redirect_to event_event_history_event_attendances_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.add_user.outsider')
  end

  def change_user
    @event_history = find_event_history
    authorize! @event_history
    @user = find_user

    Operations::EventHistory::UpdateUserRole.new(event_history: @event_history, user: @user, role: params[:role]).perform!
    redirect_to event_event_history_event_attendances_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.change_user.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_history_event_attendances_path(@event, @event_history)
  rescue Operations::EventHistory::UpdateUserRole::Outsider
    redirect_to event_event_history_event_attendances_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.change_user.outsider')
  end

  def remove_user
    @event_history = find_event_history
    authorize! @event_history
    @user = find_user

    Operations::EventHistory::UpdateUserRole.new(event_history: @event_history, user: @user, role: nil).perform!
    redirect_to event_event_history_event_attendances_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.remove_user.success')
  rescue ActiveRecord::RecordInvalid
    redirect_to event_event_history_event_attendances_path(@event, @event_history)
  rescue Operations::EventHistory::UpdateUserRole::Outsider
    redirect_to event_event_history_event_attendances_path(@event, @event_history), notice: I18n.t('notice.events/event_histories.remove_user.outsider')
  end

  def appeal
    @event_history = find_event_history
    authorize! @event_history
    redirect_to helpers.intent_url_for(@event_history)
  end

  private

  def find_user
    User.friendly.secret_or_over.find(params[:user_id])
  end

  def find_parent_event
    @event = Event.friendly.secret_or_over.find(params[:event_id])
  end

  def find_event_history
    @event.find_or_build_history(Time.zone.parse(params[:id]))
  end

  def create_params
    params.require(:event_history).permit(
      :resolution, :capacity, :default_audience_role,
      :assembled_at, :opened_at, :started_at, :ended_at, :closed_at
    )
  end

  def update_params
    params.require(:event_history).permit(
      :resolution, :capacity, :default_audience_role,
      :assembled_at, :opened_at, :ended_at, :closed_at
    )
  end
end
