# Automating acknowledgement of jobs in INACTIVE_ERROR state


### Problem statement

 Jobs going into INACTIVE_ERROR state and missing next scheduled runs unless the error is acknowledged by an operator.

### Solution overview

The example below demonstrates using subscriptions and a REST service(StreamSets pipeline) to automate acknowledgement of jobs in INACTIVE_ERROR state. For this we’ll create:

    a) A subscription to trigger on job’s INACTIVE_ERROR state
    b) REST service(deployed behind a LoadBalancer for HA) to call the Control Hub API to acknowledge the error.
    c) [Optional] NGINX server for Loadbalancing and HA

<img src="/images/inactive_error1.png" align="center" />

#### 1. Create a subscription as shown below:

<img src="/images/inactive_error5.png" align="center" />

URI: The URI points to the REST service URL in step #2. This will be the URL of the load balancer or the SDC running the REST service pipeline.

Subscription Payload:
````
{
      "JOB_ID":"{{JOB_ID}}"
}
````

#### 2. Create a REST service [pipeline](INACTIVE_ERROR_Job_ACK.json)

<img src="/images/inactive_error2.png" align="center" />

REST Service configuration example:

<img src="/images/inactive_error3.png" align="center" />

Control Hub API configuration example:

<img src="/images/inactive_error4.png" align="center" />

Control Hub URL: *https://<ControlHub-URL>/jobrunner/rest/v1/job/${record:value("/JOB_ID")}/acknowledgeError*

#### 3. [Optional] If configuring NGINX load balancer, you can use a Docker command like below:
````
docker run --name my-nginx --network=cluster  -v /<host-path>/nginx.conf:/etc/nginx/nginx.conf:ro -d -p <custom-port>:80 nginx
````
** Sample nginx configuration is available [here](nginx.conf)    
