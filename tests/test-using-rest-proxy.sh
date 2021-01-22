# Produce a message using JSON with the value '{ "foo": "bar" }' to the topic test-topic
echo "Producing message 1"
curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"records":[{"value":{"foo":"bar 1"}}]}' "http://localhost:8082/topics/test-topic"

echo "\nProducing message 2"
curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"records":[{"value":{"foo":"bar 2"}}]}' "http://localhost:8082/topics/test-topic"

echo "\nWait to start Consuming"
sleep 5

# Create a consumer for JSON data, starting at the beginning of the topic's
# log and subscribe to a topic. Then consume some data using the base URL in the first response.
# Finally, close the consumer with a DELETE to make it leave the group and clean up
# its resources.
echo "\nCreate Consumer"
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
      --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' \
      http://localhost:8082/consumers/my_json_consumer
# Expected output from preceding command
#  {
#   "instance_id":"my_consumer_instance",
#   "base_uri":"http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance"
#  }

echo "\nSubscribe topics"
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["test-topic"]}' \
      http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance/subscription
# No content in response

echo "\nConsuming Data"
curl -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
      http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance/records
