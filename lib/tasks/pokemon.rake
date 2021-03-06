# https://phoboes.gitbooks.io/wdi-23/content/modules/nokogiri.html

namespace :pokemon do
  desc "Scrapes pokemon from the internet."
  task create: :environment do
    Pokemon.destroy_all

    # It is unnecessary to require the 'nokogiri' gem as it is in the gemfile already, however, 'open-uri' isn't (though it is inclusive with rails). We need to require it for this individual task.
    # OpenURI is an easy-to-use wrapper for Net::HTTP, Net::HTTPS and Net::FTP
    # It is possible to open an http, https or ftp URL as though it were a file
    require 'open-uri'

    # new URLs
    base_url = "http://pokemon.wikia.com/"
    index_page = "List_of_Pokémon#Generation I"

    # Unfortunately this website changed their URL slightly in order to accent the 'e' in Pokemon, which kills open-uri. It permits only ascii characters. As a result, a new gem is needed to translate the url into something open-uri can digest.

    # This step is *only* necessary in the instance of foreign characters in a url.
    # without webrick error = URI::InvalidURIError: URI must be ascii only "http://pokemon.wikia.com/List_of_Pok\u00E9mon#Generation I"

    # Get webrick's http utilities package to encode the url
    require 'webrick/httputils'

    # The URL I need to modify
    query = base_url + index_page

    # Encode it into binary using the webrick gem
    query.force_encoding('binary')
    # escape = encode
    # URI.encode("Hello there world")
    #=> "Hello%20there%20world"
    query = WEBrick::HTTPUtils.escape(query)

    # Next I used Nokogiri to process the HTML that open-uri extracts from the URL via WEBrick. If we call the index variable from the terminal, all the HTML on the base_url page is available to us.
    pokedex = Nokogiri::HTML( open(query) )
    # puts pokedex -> whole html page
    # Pokedex is the response text of the index page

    # Next I find all the table elements
    # in chrome console - poketable = document.getElementsByClassName('wikitable')
    tables = pokedex.css( ".wikitable" )

    # I target only the first table because I only want the first generation of Pokemon (the others are heathen scum, and don't exist as far as I'm concerned)
    generation_1 = tables[ 0 ]

    # Once I've selected my specific table, I get a list of table rows to iterate through.
    gen_list = generation_1.css( "tr" )

    #Each with index gives me access to the index variable, a counter for each run of the loop,
    # I use this to hard code the IDs of my models (instead of auto-increment).
    gen_list.each_with_index do |p, index|

      # Firstly I loop through each link in the table
      unless p.css( "a" )[ 1 ].nil? # If this element has data
        poke_url = p.css( "a" )[ 1 ].attributes[ "href" ].value # Extract the url (ie: /wiki/bulbasaur)

        # I use the url returned by the table and then access /that/ page and scrape the data page by page
        single_pokemon = Nokogiri::HTML( open( base_url + poke_url ))
        # Passing the contents of a webpage to the Nokogiri parser is not much different than opening a regular textfile.
        # If the webpage is stored as a file on your hard drive, you can pass it in like so - page = Nokogiri::HTML(open("index.html"))
        # The Nokogiri::HTML construct takes in the opened file's contents and wraps it in a special Nokogiri data object.


        # name = single_pokemon.css( "h1" ).text
        name = single_pokemon.css('h1').text.gsub(/Fan.*/, "") # <- thanks Brendan!
        image_list = single_pokemon.css( ".floatnone .image-thumbnail img" )
        image_list.each do |p|

        # Image extraction

        # This site is populated with several images and ads, meaning I had to be /very/ specific with my CSS selectors. In this case, because the site is poorly structured, I actually need to target images by size.


        if p.attributes[ "width" ].value == "200" && p.attributes[ "width" ] != nil
          @image = p[ "src" ]

          # I'm breaking my loop as soon as I hit a valid link (otherwise Noko will just return the last match - I want the first).
          break if @image =~ /http*/
        end
      end

      # Icon extraction - Much the same as above

      image_list.each do |p|
        if p.attributes[ "height" ].value == "32" && p.attributes[ "width" ] != nil
        @icon = p[ "data-src" ] || p.attributes[ "src" ].value
        break
        end
      end

      # Puts are stricty so I can see my data is valid, the last thing I do is generate.
      # Sometimes rake tasks take a /long/ time to complete. It is a useful tool for seeing whether data is actually being found, and where it may break.



      puts index
      puts name
      puts @icon
      puts @image
      puts ""

      # Once I've validated all my data, I finally generate a model.
      @pokemon = Pokemon.create( id: index, name: name, icon: @icon, image:@image )

    end # end unless
  end # end gen_list
  end # end create
end # end task
