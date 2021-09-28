# Custom management of subscriptions-based notifications

This is a more comprehensive example covering a design pattern developed by [Mark Brooks](https://github.com/onefoursix) for customizing the management of subscriptions-based notifications 

### Example Use Case

Consider a running pipeline that is successfully writing to Kafka and then, for some reason, the Kafka cluster becomes unreachable.  
Assume the pipeline is configured to retry infinitely and that a Control Hub Subscription is configured to push outbound webhooks to a Slack Channel for the [Job Status Change Event](https://docs.streamsets.com/portal/#controlhub/latest/help/controlhub/UserGuide/Subscriptions/Events.html#concept_gjm_d5t_mfb). 
As the retry logic of the pipeline executes, one might receive a frequent and steady stream of notifications, like this:

<img src="/customersuccess/images/custom_notifications_1.png" align="center" />

Once the original notification with the Kafka timeout error message has been received, admins may wish to suppress the steady stream of similar notifications for a period of time, for example for every 15 or 30 minutes, until the issue is resolved, rather than getting multiple notifications every five minutes.

### Using SDC and Kafka to Manage Control Hub Notifications
One way to allow admins to configure custom Control Hub notification handling is to use a pair of SDC pipelines as depicted below:

<img src="/customersuccess/images/custom_notifications_2.png" align="center" />

The HTTP to Kafka pipeline instances are SDC Microservice Pipelines (behind a Load Balancer for HA) configured as the target for Control Hub's outbound Webhook notifications.  The pipeline instances publish all notifications to a Kafka topic, analogous to a [Kafka REST-Proxy](https://github.com/confluentinc/kafka-rest).

The second pipeline consumes notifications from the Kafka topic and performs any desired aggregation, enrichment, and filtering before forwarding notifications to one or more targets such as Slack, PagerDuty, Microsoft Teams, Email, etc...

### Benefits of Buffering Notifications with Kafka

1. This pattern, with notifications buffered by Kafka, provides several benefits:

2. The second pipeline's logic (aggregation, enrichment and filtering) can be changed, and the second pipeline can be restarted, without interrupting or missing any messages, unlike a "single pipeline" solution with an HTTP Client Origin that might miss messages when restarted.

3. Notifications can be reprocessed as needed by resetting the consumer group offset of the second pipeline.

4. A retention period can be set for all received notifications using Kafka's message retention property.

5. Fine grained logic can be applied to different subsets of pipeline notifications.  For example, notifications for mission-critical pipelines might never be suppressed, but notifications for ad-hoc pipelines could be.

6. A single Control Hub Subscription can be used to send notifications to multiple targets simultaneously, including multiple Webhooks and email.

7. The notification message format can be dynamically created in the second pipeline (using a number of options including templates) rather than hard-coded in the Control Hub outbound Webhook definition.  This simplifies the configuration of the Control Hub Subscription.

### Control Hub Subscription
A Control Hub Subscription that listens for Job Status Change events and forwards them as outbound Webhooks to the first pipeline, with just the parameter values of the change,  might be configured like this:

<img src="/customersuccess/images/custom_notifications_3.png" align="center" />

The Payload for the outbound Webhook is:

````
{
  "notification_type": "JOB_STATUS_CHANGE",
  "notification_payload": {
    "JOB_NAME": "{{JOB_NAME}}",
    "JOB_ID": "{{JOB_ID}}",
    "TRIGGERED_ON": "{{TRIGGERED_ON}}",
    "FROM_COLOR": "{{FROM_COLOR}}",
    "FROM_STATUS": "{{FROM_STATUS}}",
    "TO_COLOR": "{{TO_COLOR}}",
    "TO_STATUS": "{{TO_STATUS}}",
    "ERROR_MESSAGE": "{{ERROR_MESSAGE}}"
  }
}
````
Note the top level elements **notification_type** and **notification_payload** allow multiple different event subscriptions to share the same Kafka topic, as each message will have identifying information and can be sorted out using a Stream Selector in the second pipeline.

### Pipeline 1: Control Hub Notifications to Kafka
The first pipeline is an [SDC Microservice pipeline](https://docs.streamsets.com/portal/#datacollector/latest/help/datacollector/UserGuide/Microservice/Microservice_Title.html#concept_gzw_tdm_p2b) that looks like this:

<img src="/customersuccess/images/custom_notifications_4.png" align="center" />

The REST Service Origin is configured to listen on port 18888 and requires clients (including the Control Hub Webhook) to set the HTTP header *X-SDC-APPLICATION-ID* with the value *12345*:

<img src="/customersuccess/images/custom_notifications_5.png" align="center" />

Here is a sample notification received by the REST Service Origin:

<img src="/customersuccess/images/custom_notifications_6.png" align="center" />

This pipeline should be deployed using a Job with [at least 2 instances](https://docs.streamsets.com/portal/#controlhub/latest/help/controlhub/UserGuide/Jobs/Jobs-PipelineInstances.html#concept_abz_mkl_rz), behind a Load Balancer, for HA purposes.

### Pipeline 2: Control Hub Notification Handler
The second pipeline could look like this

<img src="/customersuccess/images/custom_notifications_7.png" align="center" />

This pipeline consumes messages from the Kafka topic and routes them to notification-type specific handlers.  
For example, Pipeline Commit events could be forwarded unchanged to Jenkins to kick-off CI/CD processes, and Job Status Change events could be filtered to suppress dupes within a 15 minute window and then forwarded to both Slack and Email.  
Suppressed Job Status Changed events can be written to an Audit Log.

### Routing notifications to notification-type handlers
The Notification Type Router routes messages based on the top level **notification-type** field from the original Webhook payload:

<img src="/customersuccess/images/custom_notifications_8.png" align="center" />

### Job Status Change Notification Handler

Here is an example Jython Job Status Change Notification Handler implementation that suppresses "matching" Job Status Change notifications for a user defined period such as 15 minutes, with "matching" defined as notifications having the same **JOB_ID**, **FROM_COLOR**, **FROM_STATUS**, **TO_COLOR** and **TO_STATUS**.

The pipeline takes two input parameters: a number of minutes within which to suppress duplicate notifications, and a directory for the suppressed notifications log:

<img src="/customersuccess/images/custom_notifications_9.png" align="center" />

The main Jython script for the Job Status Change Notification Handler is posted [here](https://gist.github.com/onefoursix/3a5777502085bf32c3ed61a2e85d5ea3#file-custom_control_hub_notification_handler-jy).

The Job Status Change Notification Handler implements this logic:
````
 - The Jython Evaluator maintains a cache of notifications with a timestamp for each distinct notification per Job. 

 - If the notification has never been seen before it add it to the cache with a timestamp and sends the notification to the endpoints

 - If the notification has been seen before, retrieve the timestamp from the cache for the previously-seen same event.

 - If the timestamp of the notification in the cache plus the dupe wait time is greater than the current time, consider the notification a dupe, suppress it, and write it to the suppressed notification log

 - If the timestamp of the notification in the cache plus the dupe wait time is not greater  than the current time, send the notification to the endpoints and update the notification in the cache with the current timestamp

 - The actual notification is formatted using a template (see screenshot below)

 - Each notification record will have a record attribute named send_notification set to "true" or "false". This attribute is used by a "Filter Suppressed" Stream Selector as shown below.
````
Here is the init script for the  Job Status Change Notification Handler that sets up the cache and the notification template

<img src="/customersuccess/images/custom_notifications_10.png" align="center" />

Here is the init script for easy copy and paste:
````
sdc.state['notification_template'] = 'Job Status Change for Job {} with Job ID {} at {} from {} {} to {} {}'
sdc.state['cache'] = {}
````

Here is an example of a JSON payload getting formatted as a notification message that will be sent to the endpoints. Note also the **send_notification** is set to "true":

<img src="/customersuccess/images/custom_notifications_11.png" align="center" />

### Monitoring Suppressed Messages
One can see the number of delivered vs suppressed notifications by viewing the "Filter Suppressed" Stream Selector.  
In this case, of 129 Job Status Changed notifications, 14 were forwarded to Slack and 115 were suppressed:

<img src="/customersuccess/images/custom_notifications_12.png" align="right" />

One can validate the correct behavior by correlating timestamps in the notifications received over Slack with the notifications written to the suppressed notification log.

### Monitor the Notification Management Jobs
If the pattern described above is implemented, the result will be two Jobs that manage how Control Hub notifications get routed to target systems.  
To ensure that any issues in these two Jobs are always known right away (and are never suppressed), create a dedicated Subscription that monitors the Job status of just these two Jobs and that sends notifications directly to the Admin team.

 




