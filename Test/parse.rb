require "curb"
require "nokogiri"
require "csv"


# function create csv file
def create_csv(name_file)
  CSV.open(name_file, "a") do |csv|
    csv << ["Name", "Price", "Image"]
  end
  puts "CSV file created"
end


# function parsing
def parse(url, name_file)
  puts "Data parsing begins"
  i  = 1
  url_page = url
  # start the cycle through the category pages
  loop do
    puts "Parsing of #{i} category page starts..."
    # download url page
    curl = Curl::Easy.new(url_page)
    curl.perform
    # check if url exists
    if curl.status != "200 OK"
      break
    end
    html_categorie = Nokogiri::HTML(curl.body_str)
    # takes links of all products
    arr = html_categorie.xpath("//*[@id='product_list']/li/div/div/div[1]/a/@href")
    # pass through each product
    arr.each do |href|
      # download url page
      curl = Curl::Easy.new(href.text)
      curl.perform
      html = Nokogiri::HTML(curl.body_str)
      # take the title and link pictures
      product_name = html.xpath("//*[@id='center_column']/div/div/div[2]/div/h1").text
      product_image = html.xpath("//*[@id='bigpic']/@src").text
      # add all prices to the list
      array_price = []
      product_price = html.xpath("//*[@id='attributes']/fieldset/div/ul/li/label/span[2]")
      product_price.each do |price|
        array_price << price.text.split('/')[0]
      end
      # add all weights to the list
      array_weight = []
      product_weight = html.xpath("//*[@id='attributes']/fieldset/div/ul/li/label/span[1]")
      product_weight.each do |weight|
        array_weight << weight.text
      end
      # create hash
      multi_product = Hash[array_price.zip array_weight]
      # write to CSV file
      multi_product.each do |price, weight|
        product_full_name = product_name + ' - ' + weight
        CSV.open(name_file, "a") do |csv|
          csv << [product_full_name, price, product_image]
        end
      end
    end
    puts "success!"
    # next category page
    i+= 1
    url_page = url + "?p=" + "#{i}"
  end
end


if __FILE__ == $0
  # arguments
  url = ARGV[0]
  name_file = ARGV[1] + ".csv"

  puts "Started parsing url #{url} to csv file #{name_file}. Please wait..."
  create_csv(name_file)
  parse(url, name_file)
  puts "Finished!"
end
