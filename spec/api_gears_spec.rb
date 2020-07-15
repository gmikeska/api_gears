require "api_gears"
require_relative "../spec/example_api"
describe ApiGears do
  example_api = ExampleApi.new
  describe "args_for" do
    context "called with an endpoint symbol" do
      it "responds to endpoint method calls" do
        expect(example_api.args_for(:address_info)).to eql([:address])
      end
    end
  end
  describe "query_params_for" do
    context "for an endpoint with no query params" do
      it "returns empty array" do
        expect(example_api.query_params_for(:address_info)).to eql([])
      end
    end
  end
  describe "request_info" do
    context "for an endpoint with one arg and no query params" do
      it "prints request info to the console" do
        expect { example_api.request_info(:address_info,address:"18cBEMRxXHqzWWCxZNtU91F5sbUNKhL5PX") }.to output(<<-MESSAGE).to_stdout
this method will GET https://api.blockcypher.com/v1/btc/main/addrs/18cBEMRxXHqzWWCxZNtU91F5sbUNKhL5PX?
With query params:
MESSAGE
      end
    end
  end
  describe "call to an endpoint" do
    context "with url set in the initializer" do
      data = example_api.address_info(address:"18cBEMRxXHqzWWCxZNtU91F5sbUNKhL5PX")
      it "responds to endpoint method calls" do
        expect(data.is_a? Hash).to be_truthy
        expect(data.keys).to eql( ["address", "total_received", "total_sent", "balance", "unconfirmed_balance", "final_balance", "n_tx", "unconfirmed_n_tx", "final_n_tx", "txrefs", "hasMore", "tx_url"])
      end
    end
  end
end
