This example explains following concepts 
-> Along with example_1 concepts
-> systemd-slow-service.service service which run forever using dummy.sh script.
-> systemd-cleanup-service.service (using cleanup.sh script) which stops systemd-slow-service.service
-> Timer services with OnCalendar, AccuracySec properties
-> Two timer service's starts with different time interval to properly coordinate each other.
-> deploy_scripts.sh scripts with configure and deploys the services and timers.
