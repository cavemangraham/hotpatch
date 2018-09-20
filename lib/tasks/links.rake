namespace :links do
  desc "TODO"
  task update: :environment do
    p "ADDING LINK DATA"
    secret_key = ENV['LINK_PREVIEW_KEY']

    @links = Link.where(published: [nil,'']).limit(4)

    @links.each do |link|
      link_url = link.url
      response = HTTParty.get('http://api.linkpreview.net/?key=' + secret_key + '&q=' + link_url)
      parsed_response = ActiveSupport::JSON.decode(response.body.to_s)

      link.title = parsed_response["title"]
      link.description = parsed_response["description"]
      link.preview = parsed_response["image"]
      link.published = Time.current
      link.save
    end

    p "TWEETING LINKS"

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_TOKEN_SECRET']
    end

    @links.each do |link|
      client.update("#{@link.title} #{@link.url}")
    end

    # SENDING MAIL

    p "SENDING MAIL"

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
          "linktitle1": "<a href='#{@links.first.url}'>#{@links.first.title}</a>",
          "linkdesc1": "#{@links.first.description}",
          "linktitle2": "<a href='#{@links.second.url}'>#{@links.second.title}</a>",
          "linkdesc2": "#{@links.second.description}",
          "linktitle3": "<a href='#{@links.third.url}'>#{@links.third.title}</a>",
          "linkdesc3": "#{@links.third.description}",
          "linktitle4": "<a href='#{@links.fourth.url}'>#{@links.fourth.title}</a>",
          "linkdesc4": "#{@links.fourth.description}"
        }
      }
    }

    gibbon.campaigns(campaign_id).content.upsert(body: content)
    gibbon.campaigns(campaign_id).actions.send.create
  end
end



