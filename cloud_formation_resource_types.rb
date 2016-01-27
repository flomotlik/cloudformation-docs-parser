require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'yaml'

response = Net::HTTP.get_response(URI.parse 'http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html')

AWS_SERVICES = response.body.scan(/AWS::[A-Z][::|a-zA-Z1-9]*+/).uniq.sort

AWS_SERVICES_LINKS = response.body.scan(/aws\-properties.*?.html/).uniq.sort

# AWS_SERVICES_LINKS = ['http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html']

properties = AWS_SERVICES_LINKS.inject({}) do |hash, link|
  link = 'http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/' + link
  puts link
  doc = Nokogiri::HTML(open(link))

  xpath_match=doc.xpath("(//pre[@class='programlisting']/code)[1]")[0].to_s

  xpath_match.gsub!(/<.*?>/, '')
  xpath_match.gsub!("\n", '')
  xpath_match.gsub!(/: ([a-zA-Z]+?),/, ': "\1",')
  xpath_match.gsub!(/\[ ([a-zA-Z ]*)[,. ]+\]/, '"[ \1 ]"')
  xpath_match.gsub!(/"([ ]*)"/, '",\1"')

  json = JSON.parse(xpath_match)
  hash[json['Type']] = json['Properties']
  hash
end
results = {}

results['Resources'] = properties
puts results.to_yaml.to_s
