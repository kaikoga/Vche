class UsersController < ApplicationController::Bootstrap
  skip_before_action :require_login, only: [:index, :new, :create, :show]

  def index
    @users = User.public_or_over.page(params[:page])
    authorize!
  end

  def show
    @user = find_user
    authorize! @user

    @form = CalendarPresenterForm.new(@user.following_events.invite_or_over, show_params)
    @calendar = @form.presenter(current_user: current_user, display_user: @user, candidate: false, offline: true)
  end

  def info
    @user = find_user
    authorize! @user
  end

  def events
    @user = find_user
    authorize! @user

    @form = UserEventsForm.new(@user, events_params, paginate: true, exclude: [:created])
    @events = @form.events.includes(:event_schedules, :event_histories)
  end

  def new
    @user = User.new(visibility: :public)
    authorize! @user
  end

  def edit
    @user = find_user
    authorize! @user
  end

  def create
    @user = User.new(create_params)
    authorize! @user

    if @user.save
      redirect_to :users, notice: I18n.t('notice.users.create.success')
    else
      render :new
    end
  end

  def update
    @user = find_user
    authorize! @user
    if @user.update(update_params)
      redirect_to @user, notice: I18n.t('notice.users.update.success')
    else
      render :edit
    end
  end

  private

  def find_user
    User.friendly.secret_or_over.find(params[:id])
  end

  def show_params
    @show_params ||= params.permit(:calendar, :date)
  end

  def create_params
    params.require(:user).permit(
      :email,
      :visibility, :user_role, :display_name, :primary_sns_url, :bio,
      :password, :password_confirmation
    )
  end

  def update_params
    params.require(:user).permit(
      :visibility, :user_role, :display_name, :primary_sns_url, :bio
    )
  end

  def events_params
    params.permit(:filter, :page)
  end
end
