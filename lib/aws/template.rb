require "aws-sdk"
require "json"

require "aws/template/helper"
require "aws/template/version"

module AWS
  class Template
    include Helper

    SRC = File.expand_path(File.join(File.dirname(__FILE__), 'template'))

    autoload  :VPC, "#{SRC}/vpc"
    autoload  :Subnet, "#{SRC}/subnet"
    autoload  :IGW, "#{SRC}/igw"
    autoload  :Route, "#{SRC}/route"
    autoload  :SecurityGroup, "#{SRC}/security_group"
    autoload  :KeyPair, "#{SRC}/key_pair"
    autoload  :LoadBalancer, "#{SRC}/load_balancer"
    autoload  :EC2, "#{SRC}/ec2"
    autoload  :R53, "#{SRC}/r53"

    def self.use(template_type, override_path = nil)
      require_path = "aws/template/" + template_type.gsub(/\-/, '_')
      require require_path

      klass = ("AWS::Template::" + template_type.capitalize.gsub(/\-([a-z\d])/) {|s| s[1..1].upcase}).split('::').inject(Object) {|o, c| o.const_get c}
      return klass.new(override_path)
    end

    def apply(customized_path, *args)
      @customized_path = customized_path

      config = override(@template_path, @override_path)
      execute_apply(config, *args)

      store(config, @customized_path)
    end

    def destroy(customized_path, *args)
      config = parse(customized_path)
      execute_destroy(config, *args)
    end

    def confirm(message)
      print message + " "
      r = gets.strip
      if r != "y"
        puts "aboting..."
        return false
      end

      return true
    end

    protected
    def initialize(override_path)
      @template_path = nil
      @override_path = override_path

      # xxx
      @ec2 = AWS.ec2
      @elb = AWS.elb
      @r53 = AWS.route_53
    end

    def execute_apply(config, *args)
      # to be overridden
    end

    def execute_destroy(config, *args)
      # to be overridden
    end

    def vpc
      return @vpc if @vpc
      @vpc = VPC.new(@ec2)
    end

    def subnet
      return @subnet if @subnet
      @subnet = Subnet.new(@ec2)
    end

    def igw
      return @igw if @igw
      @igw = IGW.new(@ec2)
    end

    def route
      return @route if @route
      @route = Route.new(@ec2)
    end

    def security_group
      return @security_group if @security_group
      @security_group = SecurityGroup.new(@ec2)
    end

    def key_pair
      return @key_pair if @key_pair
      @key_pair = KeyPair.new(@ec2)
    end

    def load_balancer
      return @load_balancer if @load_balancer
      @load_balancer = LoadBalancer.new(@elb)
    end

    def ec2
      return @ec2_internal if @ec2_internal
      @ec2_internal = EC2.new(@ec2)
    end

    def r53
      return @r53_internal if @r53_internal
      @r53_internal = R53.new(@r53)
    end

    def override(template_path, override_path)
      template_config = parse(template_path)
      override_config = parse(override_path)

      # deep merge
      merger = proc {|key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2}
      config = template_config.merge(override_config, &merger)

      key_value_map = {}
      build_key_value_map(config, key_value_map)
      apply_macro(config, key_value_map)

      return config
    end

    def store(config, customized_path)
      log("generating config file [#{customized_path}]...", false)
      File::open(customized_path, "w") do |f|
        f.write(JSON.pretty_generate(config))
      end
      log("ok")
    end

    def parse(json_path)
      return {} if json_path.nil?

      config = JSON.parse(File.open(json_path).read())
    end

    def build_key_value_map(config, key_value_map = {}, key = "")
      if config.is_a?(Array)
        config.map.with_index {|e, i| build_key_value_map(e, key_value_map, key + "[" + i.to_s + "]")}
      elsif config.is_a?(Hash)
        config.map {|k,v| build_key_value_map(v, key_value_map, key + (key.empty?() ? "" : "::") + k)}
      elsif config.respond_to?(:to_s)
        key_value_map[key] = config
      else
        # no way
        config
      end
    end

    def apply_macro(config, key_value_map)
      if config.is_a?(Array)
        config.each_index {|i| config[i] = apply_macro(config[i], key_value_map)}
        return config
      elsif config.is_a?(Hash)
        # update keys first
        config.keys.each {|k| k_applied = k.gsub(/{{(.*?)}}/) {|s| /{{(?<key>.*)}}/ =~ s; key_value_map[key]}; config[k_applied] = config.delete(k) }
        config.keys.each {|k| config[k] = apply_macro(config[k], key_value_map)}
        return config
      elsif config.is_a?(String)
        return config.gsub(/{{(.*?)}}/) {|s| /{{(?<key>.*)}}/ =~ s; key_value_map[key]}
      else
        return config
      end
    end

  end
end
