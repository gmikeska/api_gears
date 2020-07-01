class ExampleApi < ApiGears
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
