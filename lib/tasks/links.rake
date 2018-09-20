namespace :links do
  desc "TODO"
  task update: :environment do
    @link_preview_key = ENV['LINK_PREVIEW_KEY']

    p "Updating Links"
    secret_key = @link_preview_key

    @links = Link.where(published: [nil,'']).limit(4)

    @links.each do |link|
      link_url = link.url
      response = HTTParty.get('http://api.linkpreview.net/?key=' + secret_key + '&q=' + link_url)
      parsed_response = ActiveSupport::JSON.decode(response.body.to_s)

      link.title = parsed_response["title"]
      link.description = parsed_response["description"]
      link.preview = parsed_response["image"]
      link.published = Time.current
      p link.title
      p link.description
      p link.preview
      link.save

    end

  end

  task mail: :environment do
    @mailchimp_key = ENV['MAILCHIMP_KEY']
    p "sending mail"

    begin
    #hotpatch newsletter id
    list_id = "ed95d0c7fa"
    template_id = 207009


    gibbon = Gibbon::Request.new(api_key: @mailchimp_key)

    recipients = {
      list_id: list_id
    }

    settings = {
      subject_line: "Hotpatch Daily",
      title: "Hotpatch",
      from_name: "Hotpatch.io",
      reply_to: "hello@hotpatch.io",
      template_id: template_id
    }


    body = {
      type: "regular",
      recipients: recipients,
      settings: settings,
    }

      campaign = gibbon.campaigns.create(body: body)
    rescue Gibbon::MailChimpError => e
      puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
    end

    p "campaign created"


      campaign_id = campaign.body["id"]

      content = {
          template: {
          id: template_id,
          sections: {
            "link": "Content here"
          }
        }
      }


      gibbon.campaigns(campaign_id).content.upsert(body: content)

      #gibbon.campaigns(campaign_id).actions.send.create
  end

end
