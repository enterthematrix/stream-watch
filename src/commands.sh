Jenkins Setup:

docker build -t jenkins .
docker run --network=cluster -h jenkins--name jenkins -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins


StreamWatch:

StreamWatch-1:
docker run -d --network=cluster -h StreamWatch-1 --name StreamWatch-1 -p 20001:18630 -p 18888:18888 -e STREAMSETS_DEPLOYMENT_SCH_URL=https://na01.hub.streamsets.com -e STREAMSETS_DEPLOYMENT_ID=b43ff6c3-79af-4624-a191-8ff7d6e92085:241d5ea9-f21d-11eb-a19e-07108e36db4e -e STREAMSETS_DEPLOYMENT_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJzIjoiMjI2OTA3ODI0NjY5YmRhMzU5OTNhZmVjYzg5ZWUyMzIwYjlmMzdkMjQzNzQ5MDFjNTRkYjBlMDM2NTgxMmFjZmQ1NTY5MDZmYzVkNmJmYzUwNTc1ZTU4MTc4MTM0YWQwZGU0OGYwOWE1NjFkYjY1Yzc0NTkwZjEwODM1MWU0YTkiLCJ2IjoxLCJpc3MiOiJuYTAxIiwianRpIjoiNTViNzI2YTItMjMyOC00OWZkLWJlNTUtY2Y2MDA2YTkxZDc0IiwibyI6IjI0MWQ1ZWE5LWYyMWQtMTFlYi1hMTllLTA3MTA4ZTM2ZGI0ZSJ9. streamsets/datacollector:JDK17_5.12.0

StreamWatch-2:
docker run -d --network=cluster -h StreamWatch-2 --name StreamWatch-2 -p 20002:18630 -p 19999:19999 -e STREAMSETS_DEPLOYMENT_SCH_URL=https://na01.hub.streamsets.com -e STREAMSETS_DEPLOYMENT_ID=b43ff6c3-79af-4624-a191-8ff7d6e92085:241d5ea9-f21d-11eb-a19e-07108e36db4e -e STREAMSETS_DEPLOYMENT_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJzIjoiMjI2OTA3ODI0NjY5YmRhMzU5OTNhZmVjYzg5ZWUyMzIwYjlmMzdkMjQzNzQ5MDFjNTRkYjBlMDM2NTgxMmFjZmQ1NTY5MDZmYzVkNmJmYzUwNTc1ZTU4MTc4MTM0YWQwZGU0OGYwOWE1NjFkYjY1Yzc0NTkwZjEwODM1MWU0YTkiLCJ2IjoxLCJpc3MiOiJuYTAxIiwianRpIjoiNTViNzI2YTItMjMyOC00OWZkLWJlNTUtY2Y2MDA2YTkxZDc0IiwibyI6IjI0MWQ1ZWE5LWYyMWQtMTFlYi1hMTllLTA3MTA4ZTM2ZGI0ZSJ9. streamsets/datacollector:JDK17_5.12.0

docker run --name nginx --network=cluster  -v ~/nginx/nginx.conf:/etc/nginx/nginx.conf:ro -d -p 8081:80 nginx


ngrok http 8081 --log=stdout > ngrok.log &
/home/ubuntu/.ngrok2/ngrok.yml

Sample notification data:

{
   "notification_type":"JOB_STATUS_CHANGE",
   "notification_payload":{
      "JOB_NAME":"Job for FS_To_MySQL",
      "JOB_ID":"2e54d19e-d268-49b9-a82a-83e237475c91:241d5ea9-f21d-11eb-a19e-07108e36db4e",
      "TRIGGERED_ON":"2024-11-18 21:29:37",
      "FROM_COLOR":"RED",
      "FROM_STATUS":"INACTIVE_ERROR",
      "TO_COLOR":"RED",
      "TO_STATUS":"INACTIVE_ERROR",
      "ERROR_MESSAGE":"JOBRUNNER_64 - Force stopping job"
   }
}

{
   "notification_type":"ENGINE_NOT_RESPONDING",
   "notification_payload":{
      "SDC_ID":"b316b82f-291d-41dd-9a41-626d52898e55",
      "HTTP_URL":"http://sdc.cluster:18440",
      "LAST_REPORTED_TIME":"1658709396547"
   }
}


curl -i -X POST https://a85d-35-162-35-89.ngrok-free.app --header "X-SDC-APPLICATION-ID:StreamWatch" --header "Content-Type:application/json" -d '{"notification_type":"JOB_STATUS_CHANGE","notification_payload":{"JOB_NAME":"Job for FS_To_MySQL","JOB_ID":"2e54d19e-d268-49b9-a82a-83e237475c91:241d5ea9-f21d-11eb-a19e-07108e36db4e","TRIGGERED_ON":"2024-11-18 21:29:37","FROM_COLOR":"RED","FROM_STATUS":"INACTIVE_ERROR","TO_COLOR":"RED","TO_STATUS":"INACTIVE_ERROR","ERROR_MESSAGE":"JOBRUNNER_64 - Force stopping job"}}'

${ControlHub_URL}/jobrunner/rest/v1/job/${record:value("/notification_payload/JOB_ID")}/acknowledgeError
${ControlHub_URL}/jobrunner/rest/v1/job/2e54d19e-d268-49b9-a82a-83e237475c91:241d5ea9-f21d-11eb-a19e-07108e36db4e/acknowledgeError
curl -X POST https://na01.hub.streamsets.com/jobrunner/rest/v1/job/2e54d19e-d268-49b9-a82a-83e237475c91:241d5ea9-f21d-11eb-a19e-07108e36db4e/acknowledgeError -H "Content-Type:application/json" -H "X-Requested-By:curl" -H "X-SS-REST-CALL:true" -H "X-SS-App-Component-Id: $CRED_ID_INGESTHUB" -H "X-SS-App-Auth-Token: $CRED_TOKEN_INGESTHUB" -i


CI/CD:


docker run -d --name elasticsearch \
  --network=cluster \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=true" \
  -e "ELASTIC_PASSWORD=changeme" \
  docker.elastic.co/elasticsearch/elasticsearch:7.9.0


stf --docker-image streamsets/testframework-4.x:latest test -vs \
--aster-server-url "https://cloud.login.streamsets.com" \
--sch-credential-id ${CRED_ID_INGESTHUB} --sch-token ${CRED_TOKEN_INGESTHUB} \
--sch-authoring-sdc 'b9cece53-b256-468d-a087-449adc550083' \
--pipeline-id '50766b07-cd88-43e6-a797-7824d7d32cfb:241d5ea9-f21d-11eb-a19e-07108e36db4e' \
--sch-executor-sdc-label 'StreamWatch' \
--database 'mysql://1df425860d53:3306/default?useSSL=false' \
--elasticsearch-url 'http://elastic:changeme@c3ccd32c88ba:9200' \
test_tdf_data_to_elasticsearch.py