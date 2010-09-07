require 'rubygems'
require 'bacon'
begin
  require 'greeneggs'
rescue LoadError
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'jruby_streaming_update_solr_server'

DIR = File.dirname(__FILE__)

Bacon.summary_on_exit
