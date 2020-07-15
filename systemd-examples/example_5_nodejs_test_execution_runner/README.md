This example explains following concepts 
-> This example is node JS testcase executor using Node Mocha testcase framework
-> Executor is invoked from systmd .service unit file and .service file is mapped with .timer unit file.
-> This example also has RPM spec file which can be used to create RPM file.For more info on this study previous example_4.
-> To generate .rpm file execute ./generate_rpm_file.sh script.

Following functionalities are implemented in NodeJS testcase executor.

-> Executes all the test cases at configured scheduler time.
-> This test case runner will run test based on dc-list configured in configuration file - nodejs-testcase-runner.config.
-> Each sub-directories test cases are executed in batch in which batch size is configurable.Sub-directories are also configurable.
-> Once , each dc testing is completed it will create compressed logs in /var/logs/dc_automation
-> Sending email once after all test cases are executed in each sub-directory.
 
