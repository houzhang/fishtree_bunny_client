require "fishtree_bunny_client/version"
require "fishtree_bunny_client/queue_publisher"
require "yaml"

Rabbit = YAML.load(File.read(File.expand_path('config/rabbitmq.yml')))
Rabbit.merge! Rabbit.fetch(ENV['RACK_ENV'], {}).each_with_object({}){|(k,v), h| h[k.to_sym] = v}
