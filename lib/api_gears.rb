require 'uri'
require 'net/http'
require 'date'
require 'json'
# Base class for API client development, specify endpoints with `endpoint "shortcut_name", path:"api/subpath/"` syntax and method calls to valid shortcut_names will be caught with method_missing
class ApiGears
  # Intializes a new ApiGears instance.
  #
  # @param url [String] the base url for the API being queried
  # @param options [Hash] allows setting :query_interval, global params (such as api-key, and default query_method)
  # @return [ApiGears] a new ApiGears Instance
  def initialize(url, **options)
    @uri = URI.parse(url)
    @endpoints = {}
    @last_query_time = 0
    if(!options[:query_interval].nil?)
      @query_interval = options[:query_interval]
    else
      @query_interval = 0
    end

    if(!options[:params].nil?)
      @params = options[:params]
    else
      @params = {}
    end
    if(!options[:content_type].nil?)
      @content_type = options[:content_type]
    else
      @content_type = "plain"
    end

    if(!options[:query_method].nil?)
      @query_method = options[:query_method].to_sym
    else
      @query_method = :GET
    end
  end
  # Provides information on the request an endpoint will send.
  #
  # @param endpoint [Symbol] the base url for the API being queried
  # @param args [Hash] params to flesh-out the API call.
  # @return [nil]
  def request_info(endpoint,**args)
    if(args.nil?)
      args = {}
    end
    args[:endpoint] = endpoint.to_sym
    r_info = build_request(args)
    query_method = r_info[:query_method]
    url = r_info[:url]
    puts "this method will #{query_method} #{url}"
    puts "With query params:"+r_info[:params].keys.collect{|k| "#{k}:#{r_info[:params][k]}"}.join("\n")
  end

  def request(**args)
    r_info = build_request(args)
    current_elapsed = DateTime.now.strftime('%s').to_i - @last_query_time
    if(current_elapsed < @query_interval)
      cooldown = @query_interval - current_elapsed
      puts "Sleeping #{cooldown} seconds to accomodate query interval."
      sleep(cooldown)
    end
    query_method = r_info[:query_method]
    url = r_info[:url]

    puts "#{query_method} #{url}"
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    if(query_method == :GET)
      request = Net::HTTP::Get.new(url)
      if(!@params.nil?) # Set API-wide header params, such as api-key
        @params.each_pair do |param_name,param|
          request[param_name.to_s] = param
        end
      end
    end
    if(query_method == :POST)
      request = Net::HTTP::Post.new(url)
    end
    if(query_method == :PATCH)
      request = Net::HTTP::Patch.new(url)
    end
    if(query_method == :PUT)
      request = Net::HTTP::Put.new(url)
    end

    if(query_method != :GET)
      if(@content_type == "json")
        r_info[:params] = JSON.generate(r_info[:params])
      elsif(@content_type == "plain")
        r_info[:params] = URI.encode_www_form(r_info[:params])
      end
      response = http.request(request,r_info[:params])
    else
      response = http.request(request)
    end
    @last_query_time = DateTime.now.strftime('%s').to_i
    if(response.content_type == "application/json")
      data = JSON.parse(response.read_body)
    else
      data = response.read_body
    end
    if(response.code.to_i >= 200 && response.code.to_i < 300)
      puts "success"
      return data
    else
      puts response.code.to_s+" "+response.message
    end
    # if(@endpoint[args[:endpoint][:block]])
      # return @endpoint[args[:endpoint]][:block](data)
    # else

    # end

  end
  # Handles calls to any endpoint created during initialization
  #
  # @param m [Symbol] the method name being called
  # @param args [Hash] params passed to method call
  # @param block [Block] As yet unused.
  # @return [Hash] or [Array], depending on what API returns.
  def method_missing(m, **args, &block)
    if(!@endpoints[m.to_sym].nil?)
      request(endpoint:m.to_sym,**args)
    else
      raise NoMethodError.new "endpoint '#{m}' not defined in #{self.class.name}. Call `<#{self.class.name} instance>.endpoints` to get a list of defined endpoints."
    end

  end
  # Provides a list of endpoints that can be called as method names on the ApiGears object. Api calls are caught with #method_missing
  #
  # @return [Array]
  def endpoints
    @endpoints.keys
  end
  # Provides a list of args that a particular endpoint needs to insert into url
  # @param e [Symbol] or [String]
  # @return [Array] of argument symbols sought during endpoint call.
  def args_for(e)
    if(@endpoints[e.to_sym][:args])
      return @endpoints[e.to_sym][:args].map{|arg| arg.to_sym}
    else
      return []
    end
  end
  # Provides a list of args that a particular endpoint needs. Combines url arguments and other query params.
  # @param e [Symbol] or [String]
  # @return [Array] of argument symbols sought during endpoint call.
  def required_args(e)
    if(@endpoints[e.to_sym][:args])
      return @endpoints[e.to_sym][:args].map{|arg| arg.to_sym}.concat(query_params_for(e))
    else
      return [].concat(query_params_for(e))
    end
  end
  def query_params_for(e)
    @endpoints[e.to_sym][:query_params].map{|arg| arg.to_sym}.concat(@endpoints[e.to_sym][:set_query_params].keys)
  end
  # Can be called during override of #request to modify API response data before return
  # @param data [Hash] or [Array]
  # @return [Hash] or [Array] depending on the data in the API response
  def prepare_data(data, depth=0,&block)
    if(!block.nil?)
      yield(data,depth)
    end
    depth = depth + 1
    if(data.is_a? Array)
      data.each_index do |i|
        if(!block.nil?)
          data[i] = self.prepare_data(data[i],depth, &block)
        else
          data[i] = self.prepare_data(data[i],depth)
        end
      end
    end
    if(data.is_a? Hash)
      data.symbolize_keys!
      data.each_pair do |k,v|
        if(!block.nil?)
          data[k] = self.prepare_data(v,depth, &block)
        else
          data[k] = self.prepare_data(v,depth)
        end
      end
    end
    return data
  end
  private
    def build_request(args)
      if(args[:endpoint])
        endpoint_data = @endpoints[args[:endpoint].to_sym]
      end
      if(args[:query_method])
        args[:query_method] = args[:query_method].to_s.upcase.to_sym
      elsif(endpoint_data[:query_method])
        args[:query_method] = endpoint_data[:query_method].to_s.upcase.to_sym
      else
        args[:query_method] = @query_method.to_s.upcase.to_sym
      end
      uf = url_for(args[:endpoint],args)
      return {query_method:args[:query_method],**uf}
    end
    # Allows implementer to specify an API endpoint to be queried by a specific method name.
    # @param name [String] the method name that will execute the query
    # @param args [Hash] accepts path (subpath to query), query_params (query parameters to be sent when method is called) and set_query_params (query parameters that are specified ahead of time for each execution of the method being defined)
    # @return [nil]
    def endpoint(name, **args, &block)
      if(args[:path] == nil)
        args[:path] = "/#{name.to_s}"
      end
      if(args[:args].nil?)
        args[:args] = []
      else
        args[:args] = args[:args].map do |arg_name|
          arg_name.to_sym
        end
      end
      if(args[:path].match(/\{([a-zA-Z_0-9\-]*)\}/))
        path_args = args[:path].scan(/\{([a-zA-Z_0-9\-]*)\}/).flatten
        path_args.each do |name|
          args[:args] << name.to_sym
        end
      end
      if(args[:query_params].nil?)
        args[:query_params] = {}
      end
      if(args[:set_query_params].nil?)
        args[:set_query_params] = {}
      end
      @endpoints[name.to_sym] = {path:args[:path],args:path_args,query_params:args[:query_params],query_method:args[:query_method] ,set_query_params:args[:set_query_params], block:block}
    end
    # Builds URL and args for a specific endpoint call
    # @param endpoint [String] or [Symbol] the method name that has been called
    # @param args [Hash] the args passed in during the method call, when the required arg has 2 parts, (eg "book_id"), the first part of the arg name can be used (in this case "book" though this should only be used when "book" is unique in the query)
    # @return [Hash] with url and query params
    def url_for(endpoint, args)
      url = @uri.dup

      e_path = @endpoints[endpoint.to_sym][:path]

      if(!@endpoints[endpoint.to_sym][:args].nil? && @endpoints[endpoint.to_sym][:args].length > 0)
        args_for(endpoint.to_sym).each do |arg|
          specific_arg_not_found = (args[arg].nil?)
          arg_has_two_parts = (arg.to_s.split("_").length == 2)
          arg_shortcut_found = (!args[arg.to_s.split("_")[0].to_sym].nil?)
          if(specific_arg_not_found && arg_has_two_parts && arg_shortcut_found )
            value = args[arg.to_s.split("_")[0].to_sym]
          else
            value = args[arg]
          end
          e_path = e_path.gsub("{#{arg.to_s}}", value.to_s)
        end
      end

      if(e_path.include? @uri.path)
        url.path = e_path
      else
        url.path = url.path + e_path
      end


    if(@endpoints[endpoint.to_sym][:query_params])
      query_set = {}
      query_params_for(endpoint.to_sym).each do |param|
        if(args[param.to_sym])
          query_set[param.to_sym] = args[param.to_sym]
        elsif @endpoints[endpoint.to_sym][:set_query_params][param.to_sym]
          query_set[param.to_sym] =  @endpoints[endpoint.to_sym][:set_query_params][param.to_sym]
        end
      end


      if(args[:query_method] == :GET)
        url.query = URI.encode_www_form(query_set)
        return {url:url,params:{}}
      else
        return {url:url,params:query_set}
      end
    else

      return {url:url,params:{}}
    end
  end
end
