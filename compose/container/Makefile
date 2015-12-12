.PHONY:	build push

IMAGE = fluentd-elasticsearch
TAG = v0.1.0

build:
	docker build -t we87/$(IMAGE):$(TAG) .

push:
	docker push we87/$(IMAGE):$(TAG)
