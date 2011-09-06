require "nokogiri"

builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
  xml.dictionary("xmlns"   => "http://www.w3.org/1999/xhtml", 
                 "xmlns:d" => "http://www.apple.com/DTDs/DictionaryService-1.0.rng") do
    $namespace_definitions = xml.parent.namespace_definitions
    xml.parent.namespace = $namespace_definitions[1]

    Dir["jquery_api/*/entry.html"].each_with_index do |entry_file,entry_index|
      html = Nokogiri::HTML(File.open(entry_file),nil,'utf-8')
            
      entry_name   = html.xpath('//div[@class="entry-content"]/div[1]/h1/text()').first.to_s
      
      entry_css_classes = html.xpath('//div[@class="entry-content"]/div').map do |div| 
        div.attributes["class"].value
      end.select do |css_class|
        css_class.split(/\s/).include?("entry")
      end
      
      entry_css_classes.each_with_index do |entry_css_class,entry_css_index|
        entry_content = html.xpath('//div[@class="entry-content"]/div[@class="' + 
                                                                entry_css_class + 
                                                                          '"][' + 
                                                       (entry_css_index+1).to_s + 
                                                                            ']')
                                                                            
        name            = entry_content.xpath('h2[1]/span[@class="name"]/text()').first.to_s
        formatted_name  = name.downcase.gsub(/[^a-zA-Z0-9]/,"_")

        signatures_names = []

        entry_content.xpath('div[1]/ul[@class="signatures"]/li').each do |li|
          signature_name = li.xpath('h4[1]/text()').map(&:to_s).join.strip
          break if signature_name == ""
          signatures_names << signature_name
        end

        xml['d'].entry("id" => "#{formatted_name}_#{entry_index}_#{entry_css_index}", "d:title" => "#{entry_name}", "d:value" => "#{entry_name.gsub(/[\.\:]/,"")}") do
          xml['d'].index("d:title" => "#{entry_name}","d:value" => "#{entry_name.gsub(/[\.\:]/,"")}")
          if entry_name =~ /^jQuery\./
            xml['d'].index("d:title" => "#{entry_name}","d:value" => "#{entry_name.gsub("jQuery.","").gsub(/[\.\:]/,"")}")
          end
          signatures_names.each do |signature_name|
            next if signature_name == entry_name
            xml['d'].index("d:title" => "#{signature_name}","d:value" => "#{signature.gsub(".","")}")
          end
          xml.div do
            xml.parent.namespace = $namespace_definitions[0]
            xml << entry_content.xpath('h2[1]').to_html
            xml << entry_content.xpath('div[1]/p[@class="desc"]').to_html
            xml << entry_content.xpath('div[1]/ul[@class="signatures"]').to_html
            xml << entry_content.xpath('div[1]/div[@class="longdesc"]/*').to_html
          end
        end        
      end
            
    end
  end
end

File.open("jQueryDictionary.xml","w") do |dict|
  dict.print(builder.to_xml)
end
