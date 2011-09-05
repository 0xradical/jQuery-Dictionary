require "mechanize"

unless File.exists?("jquery_api")
  FileUtils.mkdir("jquery_api")
end

agent = Mechanize.new
agent.user_agent_alias = "Windows Mozilla"
agent.follow_meta_refresh = true

api_page = agent.get "http://api.jquery.com/"

api_contents = api_page.parser.xpath('//div[@id="jq-primaryContent"]/div[@id="content"]/ul[@id="method-list"]/li')

api_contents.each_with_index do |entry_item,entry_index|
  href = entry_item.xpath("h2/a").first.attributes["href"].value

  method_page = agent.get href
  
  unless File.exists?("jquery_api/#{entry_index}")
    FileUtils.mkdir("jquery_api/#{entry_index}")
  end
  
  File.open("jquery_api/#{entry_index}/entry.html","w") do |html_file|
    html_file.print(method_page.parser.xpath('//div[@class="entry-content"]').to_html)
  end  
end