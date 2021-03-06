class Users::AccountsController < ApplicationController::Bootstrap
  before_action :find_parent_user

  def index
    authorize!
    @accounts = @user.accounts
  end

  def show
    authorize!
    @account = find_account
  end

  def info
    authorize!
    @account = find_account
  end

  def new
    @account = @user.accounts.build
    authorize! @account
  end

  def edit
    @account = find_account
    authorize! @account
  end

  def create
    @account = @user.accounts.new(account_params)
    authorize! @account

    if @account.save
      redirect_to user_accounts_path(@user), notice: I18n.t('notice.users/accounts.create.success')
    else
      render :new
    end
  end

  def update
    @account = find_account
    authorize! @account
    if @account.update(account_params)
      redirect_to [@user, @account], notice: I18n.t('notice.users/accounts.update.success')
    else
      render :edit
    end
  end

  def destroy
    @account = find_account
    authorize! @account
    @account.destroy
    redirect_to user_accounts_url(@user), notice: I18n.t('notice.users/accounts.destroy.success')
  end

  private

  def find_parent_user
    @user = User.friendly.secret_or_over.find(params[:user_id])
  end

  def find_account
    @user.accounts.find_by(uid: params[:id])
  end

  def account_params
    params.require(:account).permit(:display_name, :platform_id, :url)
  end
end
