namespace :links do
  desc "TODO"
  task update: :environment do
    p "Updating Links"
    secret_key = '5b9babd21a62f49808dd17c6b4b19dfe71f4d16e5b733'

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

end
