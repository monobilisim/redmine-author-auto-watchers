# frozen_string_literal: true

require File.expand_path('../../../../test/test_helper', __dir__)

class AuthorAutoWatchersSettingsTest < Redmine::ControllerTest
  tests SettingsController

  fixtures :users, :email_addresses

  def setup
    @request.session[:user_id] = 1 # admin
  end

  def test_settings_page_shows_rules_and_preview
    with_settings plugin_redmine_author_auto_watchers: {'rules' => "jsmith: dlopper\nnobody@example.com: dlopper"} do
      get :plugin, params: {id: 'redmine_author_auto_watchers'}
      assert_response :success
      assert_select 'textarea#settings_rules', text: /jsmith: dlopper/
      assert_select 'a[href="/users/2"]'
      assert_select 'a[href="/users/3"]'
      assert_select '.icon-warning', text: /nobody@example.com/
    end
  end
end
