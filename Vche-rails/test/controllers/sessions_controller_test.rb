require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'should get new' do
    get login_url
    assert_response :success
  end

  test 'should get create' do
    post login_url
    assert_response :success
  end

  test 'should get destroy' do
    post logout_url
    assert_response :success
  end
end
