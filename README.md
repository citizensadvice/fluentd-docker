# CA Fluentd docker image for use with AWS Beanstalk

This setup extends the official [fluent/fluent image](https://hub.docker.com/r/fluent/fluentd/) and is tailored for use with the ElasticBeanstalk's multi-container platform.


## Usage

### Default configuration

Using the default configuration fluentd will store all container logs in partitioned folders in the specified S3 bucket. The folder structure is as follows:

`<FLUENT_S3_BUCKET>/logs/application=${tag[2]}/datestamp=%Y%m%d/${tag}_%{time_slice}_%{index}.json.%{file_extension}`

> `tag` is a string separated by ‘.’s and consisting of **exactly 3 parts** (e.g. `prod.myapp.web`). It is used as the directions for Fluentd’s internal routing engine.

e.g.

`<FLUENT_S3_BUCKET>/logs/application=myapp/datestamp=20190121/docker.prod.myapp.web.i-015a41b4ef9d8b202_2019012107_1.json.gz` 

The default config file is in `/fluentd/etc/fluent.conf`.
Check [fluent.conf](./fluent.conf)

When using the bundled config fluentd will:

- tail all logs in `/var/log/containers/*.log`
- tag the logs with the tag specified with the `FLUENT_TAG` environment variable
- append the EC2 instance id to the tag. 
- upload and encrypt logs with AES256 SSE to the S3 bucket set in `FLUENT_S3_BUCKET`.

The default configuration requires the following environment variables: 

- `FLUENT_TAG` - `.` separated string of **exactly 3 parts** e.g. `prod.myapp.web`. The the middle string must be the applications name.
- `FLUENT_S3_BUCKET` - S3 bucket name without the `s3://` prefix
- `AWS_REGION` - the S3 bucket region

You also need these mounts:

- `/var/log/containers:/fluentd/incoming:ro` - allow fluentd to read container logs
- `/tmp/fluentd_pos:/fluentd/pos:rw` - folder to store fluent pos files
- `/tmp/fluentd_s3_buffer:/fluentd/s3_buffer:rw` - buffered S3 uploads

### Overriding the configuration

- mount your config to `/fluentd/etc` e.g. `-v /path/to/my.conf:/fluentd/etc`
- mount any additional folders
- set any env vars if needed

> Note: if you need additional plugins you have to extend the image; follow the instructions in the official  [fluentd docker repository](https://hub.docker.com/r/fluent/fluentd/)

### Dockerrun.aws example


```json
{
   "AWSEBDockerrunVersion":2,
   "volumes":[
      {
         "name":"container_logs",
         "host":{
            "sourcePath":"/var/log/containers"
         }
      },
      {
         "name":"fluentd_pos",
         "host":{
            "sourcePath":"/tmp/fluentd_pos"
         }
      },
      {
         "name":"fluentd_s3_buffer",
         "host":{
            "sourcePath":"/tmp/fluentd_s3_buffer"
         }
      }
   ],
   "containerDefinitions":[
      {
         "name":"app",
         "memoryReservation":256,
         "essential":true,
         "image":"myapp",
         "command":[
            "rails",
            "server"
         ],
         "portMappings":[
            {
               "hostPort":3000,
               "containerPort":3000
            }
         ]
      },
      {
         "name":"fluentd",
         "memoryReservation":64,
         "essential":true,
         "image":"ca-fluentd",
         "environment":[
            {
               "name":"AWS_REGION",
               "value":"eu-west-1"
            },
            {
               "name":"FLUENT_TAG",
               "value":"preprod.myapp.web"
            },
            {
               "name":"FLUENT_S3_BUCKET",
               "value":"cab-preprod-myapp-logs-1234567890"
            }
         ],
         "mountPoints":[
            {
               "containerPath":"/fluentd/incoming",
               "sourceVolume":"container_logs",
               "readOnly":true
            },
            {
               "containerPath":"/fluentd/pos",
               "sourceVolume":"fluentd_pos",
               "readOnly":false
            },
            {
               "containerPath":"/fluentd/s3_buffer",
               "sourceVolume":"fluentd_s3_buffer",
               "readOnly":false
            }
         ]
      }
   ]
}
```

## Releasing

Manual release, the docker tag must match the tag in the `FROM` directive in the [Dockerfile](./Dockerfile):

```bash
docker build . -t fluentd
# push to cita-devops
docker tag fluentd 979633842206.dkr.ecr.eu-west-1.amazonaws.com/fluentd:v1.13-1
docker push 979633842206.dkr.ecr.eu-west-1.amazonaws.com/fluentd:v1.13-1

# push to cab-prod so beanstalk can pull it
docker tag fluentd 170181076180.dkr.ecr.eu-west-1.amazonaws.com/fluentd:v1.13-1
docker push 170181076180.dkr.ecr.eu-west-1.amazonaws.com/fluentd:v1.13-1
```
