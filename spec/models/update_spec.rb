require 'spec_helper'

describe Update do
  describe "validations" do
    it{ should validate_presence_of :project_id }
    it{ should validate_presence_of :user_id }
    it{ should validate_presence_of :comment }
    it{ should validate_presence_of :comment_html }
  end

  describe "associations" do
    it{ should belong_to :user }
    it{ should belong_to :project }
  end

  describe ".create" do
    subject{ FactoryGirl.create(:update, :comment => "this is a comment\n") }
    its(:comment_html){ should == "<p>this is a comment</p>" }
  end

  describe "#email_comment_html" do
    subject{ FactoryGirl.create(:update, :comment => "this is a comment\nhttp://vimeo.com/6944344\nhttp://catarse.me/assets/catarse/logo164x54.png").email_comment_html }
    it{ should == "<p>this is a comment<br />\n<a href=\"http://vimeo.com/6944344\" target=\"_blank\">http://vimeo.com/6944344</a><br />\n<img src=\"http://catarse.me/assets/catarse/logo164x54.png\" alt=\"\" style=\"max-width:513\" /></p>" }
  end

  describe "#notify_backers" do
    before do
      Notification.unstub(:create_notification)
      FactoryGirl.create(:notification_type, :name => 'updates')
      @project = FactoryGirl.create(:project)
      backer = FactoryGirl.create(:backer, :confirmed => true, :project => @project)
      FactoryGirl.create(:backer, :confirmed => true, :project => @project, :user => backer.user)
      @project.reload
      ActionMailer::Base.deliveries = []
      @update = Update.create!(:user => @project.user, :project => @project, :comment => "this is a comment\nhttp://vimeo.com/6944344\nhttp://catarse.me/assets/catarse/logo164x54.png")
      Notification.expects(:create_notification_once).with(:updates, backer.user,
        {update_id: @update.id, user_id: backer.user.id},
        :project_name => backer.project.name,
        :project_owner => backer.project.user.display_name,
        :project_owner_email => backer.project.user.email,
        :from => @update.project.user.email,
        :update_title => @update.title,
        :update => @update,
        :update_comment => @update.email_comment_html).once
    end

    it 'should call Notification.create_notification once' do
      @update.notify_backers
    end
  end
end
