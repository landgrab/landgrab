# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/bulletin_mailer
class BulletinMailerPreview < ActionMailer::Preview
  def bulletin
    bulletin = Bulletin.new(
      subject: 'News from the land',
      intro: "Hello! Here's what's been happening **this month**.",
      posts: [
        Post.new(id: 999_999_999, title: 'Spring planting', preview: 'The *first* trees went in last week. [See the map](/projects)'),
        Post.new(id: 999_999_998, title: 'Open day', preview: "- Saturday 10am\n- Bring boots")
      ]
    )

    BulletinMailer.with(bulletin:, user: User.new(id: 999_999_997, first_name: 'Freya', email: 'freya@example.com')).bulletin
  end
end
