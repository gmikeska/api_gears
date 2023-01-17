# api_gears Gem

## Installation

Add this line to your application's Gemfile:

  ```gem 'api_gears'```

And then execute:

  ```$ bundle```

Or install it yourself as:

  ```$ gem install api_gears```

## Basic Usage Example
The following example implements the api for the cryptocurrency block explorer located at [View Site](http://blockcypher.com)

```ruby
class BlockcypherApi < ApiGears
  def initialize(**options)
    if(options[:params].nil?)
      options[:params] = {}
    end
    if(options[:currency].nil?)
      options[:currency] = "btc"
    end
    if(options[:chain_id].nil?)
      options[:chain_id] = "main"
    end
    options[:content_type] = "json"
    url = "https://api.blockcypher.com/v1/#{options[:currency]}/#{options[:chain_id]}"
    super(url,options)
    endpoint "address_info", path:"/addrs/{address}"
    endpoint "address_balance", path:"/addrs/{address}/balance"
    endpoint "transaction", path:"/txs/{transaction_id}"
    endpoint "generate_multisig_address", path:"/addrs",query_method: :post, query_params:[:pubkeys], set_query_params:{script_type:"multisig-2-of-3"}
  end
end
```
Example API query:
```ruby
blockcypher_api = BlockcypherApi.new
blockcypher_api.address_info(address:"1MNGRXLueAKdeUKzBEJPqPPEFkohoaVn1k")
```
returns:
```ruby
{"address"=>"1MNGRXLueAKdeUKzBEJPqPPEFkohoaVn1k", "total_received"=>519281, "total_sent"=>519281, "balance"=>0, "unconfirmed_balance"=>0, "final_balance"=>0, "n_tx"=>4, "unconfirmed_n_tx"=>0, "final_n_tx"=>4, "txrefs"=>[{"tx_hash"=>"afb235a1568c3aa73aa5d0ed6d99198ce3fb857d822586c41bf0764ae118c1c5", "block_height"=>625997, "tx_input_n"=>7, "tx_output_n"=>-1, "value"=>235203, "ref_balance"=>0, "confirmations"=>9334, "confirmed"=>"2020-04-14T22:12:21Z", "double_spend"=>false}, {"tx_hash"=>"e5ff7ca00c85c7c7eea2e03015d814386dc9f2536577031b5909726f81dcfdec", "block_height"=>625994, "tx_input_n"=>3, "tx_output_n"=>-1, "value"=>284078, "ref_balance"=>235203, "confirmations"=>9337, "confirmed"=>"2020-04-14T21:49:16Z", "double_spend"=>false}, {"tx_hash"=>"83a6453eba87c046f0a1de72cba266f9b3087ae6ec12bb662901d33d2bc771e1", "block_height"=>625340, "tx_input_n"=>-1, "tx_output_n"=>0, "value"=>284078, "ref_balance"=>519281, "spent"=>true, "spent_by"=>"e5ff7ca00c85c7c7eea2e03015d814386dc9f2536577031b5909726f81dcfdec", "confirmations"=>9991, "confirmed"=>"2020-04-10T20:50:53Z", "double_spend"=>false}, {"tx_hash"=>"8aa0896adb78e8fe6981b8de7f8171cdfc43136f5c407946369399980cd2b92f", "block_height"=>625340, "tx_input_n"=>-1, "tx_output_n"=>21, "value"=>235203, "ref_balance"=>235203, "spent"=>true, "spent_by"=>"afb235a1568c3aa73aa5d0ed6d99198ce3fb857d822586c41bf0764ae118c1c5", "confirmations"=>9991, "confirmed"=>"2020-04-10T20:50:53Z", "double_spend"=>false}], "tx_url"=>"https://api.blockcypher.com/v1/btc/main/txs/"}
```

## Handling returned data
The following example implements a portion of the api for the church management software called "Breeze". [View Site](https://www.breezechms.com/) Notice that the method "request" is overridden, and modifies the data before returning it to the caller.
```ruby
class BreezeApi < ApiGears
  def initialize(**options)
    if(options[:params].nil?)
      options[:params] = {}
    end
    options[:query_interval] = 10
    subdomain = ENV.fetch("BREEZE_SUBDOMAIN")
    if(options[:Api_key].nil? && options[:params][:Api_key].nil?)
      options[:params]['Api-key'] = ENV.fetch("BREEZE_API_KEY")
    end

    url = "https://#{subdomain}.breezechms.com/api"

    super(url,options)
    endpoint "people"
    endpoint "person", path:'/people/{person_id}'
    endpoint "add_person", path:'/people/add', query_params:["first","last"]
    endpoint "delete_person", path:'/people/delete', query_params:["person_id"]

    endpoint "events", query_params:["start","end","category_id","eligible","details","limit"]
    endpoint "event", path:'events/list_event', query_params:["instance_id","schedule","schedule_direction","schedule_limit","eligible","details"]
    endpoint "calendars", path:'/events/calendars/list'
    endpoint "locations", path:'/events/locations'
    endpoint "add_event", path:'events/add', query_params:["name","starts_on","ends_on","all_day","description","category_id","event_id"]
    endpoint "delete_event", path:'events/delete', query_params:["instance_id"]
  end
  def request(**args)
    result = super
    result = prepare_data(result)
    return result
  end
end
```
Data returns a hash as above, with all data recursively symbolized. ```prepare_data``` also accepts a block, to which it recursively passes each key value pair in the result's dataset.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
