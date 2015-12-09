#
# Fluentd Kubernetes Output Plugin - Enrich Fluentd events with Kubernetes
# metadata
#
# Copyright 2015 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class Fluent::RancherOutput < Fluent::Output
  Fluent::Plugin.register_output('rancher', self)

  config_param :container_id, :string
  config_param :tag, :string

  def initialize
    super
  end

  def configure(conf)
    super

    require 'docker'
    require 'json'
  end

  def emit(tag, es, chain)
    es.each do |time,record|
      Fluent::Engine.emit('rancher',
                          time,
                          enrich_record(tag, record))
    end

    chain.next
  end

  private

  def interpolate(tag, str)
    tag_parts = tag.split('.')

    str.gsub(/\$\{tag_parts\[(\d+)\]\}/) { |m| tag_parts[$1.to_i] }
  end

  def enrich_record(tag, record)
    id = interpolate(tag, @container_id)
    if !id.empty?
      record['container_id'] = id
      record = enrich_container_data(id, record)
      record = merge_json_log(record)
    end
    record
  end

  def enrich_container_data(id, record)
    container = Docker::Container.get(id)
    if container
      container_name = container.json['Name']
      if container_name
        record["container_name"] = container_name[1..-1] if container_name[0] == '/'
      end

      config = container.json["Config"]
      labels = config["Labels"] if config and config["Labels"]
      if labels
        if labels["io.kubernetes.pod.namespace"]
          record["project"] = labels["io.kubernetes.pod.namespace"]
          record["service"] = labels["io.kubernetes.pod.name"] if labels["io.kubernetes.pod.name"]
          record["container"] = labels["io.kubernetes.container.name"] if labels["io.kubernetes.container.name"]
        elsif labels["io.kubernetes.pod.name"]
          svc, *pod = labels["io.kubernetes.pod.name"].split("/", 2)
          record["project"] = svc
          record["service"] = pod[-1] if pod[-1]
          record["container"] = labels["io.kubernetes.container.name"] if labels["io.kubernetes.container.name"]
        else labels["io.rancher.project.name"]
          record["project"] = labels["io.rancher.project.name"]
          # 2. service name & container name
          svc_container_name = labels["io.rancher.project_service.name"]
          if svc_container_name
            svc, *cnames = svc_container_name.split('/', 3)
            record["service"] = svc
            record["container"] = cnames[-1] if cnames[-1]
          end
        end
      end
    end
    record
  end

  def merge_json_log(record)
    if record.has_key?('log')
      log = record['log'].strip
      if log[0].eql?('{') && log[-1].eql?('}')
        begin
          parsed_log = JSON.parse(log)
          record = record.merge(parsed_log)
          unless parsed_log.has_key?('log')
            record.delete('log')
          end
        rescue JSON::ParserError
        end
      end
    end
    record
  end

end
