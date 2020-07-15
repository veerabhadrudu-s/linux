let ldap = require('ldapjs');
let deasync = require('deasync');
let Config = {};

Config.logger = {
  //{ error: 0, warn: 1, info: 2, verbose: 3, debug: 4, silly: 5 }
  console: {
    level: 'silly'
  },
  //TODO Logging to file is not supported

  level: 'error',
  file: {
    level: 'debug',
    directory: process.cwd() + '/logs/'
  }
};

Config.console={
  print_full_response : false
};

//144
Config.uiot = {
  cseBase: "HPE_IoT",
  cseID: "CSE1000",
  dav: 'http://<DAV_IP>:<DAV_PORT>',    		// ***Environment Info to be replaced here***
  dsm: 'http://<DSM_IP>:<DSM_PORT>',    		// ***Environment Info to be replaced here***
  dsm_getAssetSessionContext: 'dsm/wsi/asset/getSessionContext',
  dsm_deleteAssetSession: 'dsm/wsi/asset/sessionDelete',
  dsm_getPendingMessages: 'dsm/wsi/asset/getPendingMessages',
  dsm_deletePendingMessages: 'dsm/wsi/asset/deletePendingMessages',
  dsm_username: '<DSM_USERNAME>',				// ***Environment Info to be replaced here***
  dsm_password: '<DSM_PASSWORD>',
  postgres_username: '<POSTGRES_USERNAME>', // ***Environment Info to be replaced here***
  postgres_password: '<POSTGRES_PASSWORD>', // ***Environment Info to be replaced here***
  postgres_ip: '<POSTGRES_IP>',  // ***Environment Info to be replaced here***
  postgres_port: '<POSTGRES_PORT>', // ***Environment Info to be replaced here***
  postgres_dbname: '<POSTGRES_DB_NAME>', // ***Environment Info to be replaced here***
  postgres_schema: '<POSTGRES_SCHEMA_NAME>'	// ***Environment Info to be replaced here***
};

Config.ldap = {
  url: 'ldap://<LDAP_IP>:<LDAP_PORT>',  		// ***Environment Info to be replaced here***
  login_dn: '<LDAP_LOGIN_DN>',					// ***Login_DN Details to be specified***
  login_dn_password: '<LDAP_PASSWORD>',			// ***Environment Info to be replaced here***
  readAENameFromLdap: function (ldapDN) {

    let waitTime = 20, maxLoopCount = 1000, aeName = '';
    let waitTimeOutErrorMsg = `Maximum wait period of ${waitTime * maxLoopCount} ms waited to read from LDAP.`;
    let bindingErrorMsg = `Invalid LDAP Login Credentials`;
    let ldapClient = ldap.createClient({ url: this.url });
    let ldapSearchOptions = {};

    console.log(`Reading AE Name for dn ${ldapDN}`);

    ldapClient.bind(this.login_dn, this.login_dn_password, function (err) {
      if (err)
        throw new Error(bindingErrorMsg);

      ldapClient.search(ldapDN, ldapSearchOptions, function (err, res) {
        res.on('searchEntry', function (entry) {
          aeName = entry.object.aliasedObjectName.split(',')[0].split('=')[1];
          console.log(`AE Name Read from LDAP for dn - ${ldapDN} is ${aeName}`);
          ldapClient.unbind(function (error) {
            console.error("Error while closing LDAP connection - ", error);
          });
        });
        res.on('searchReference', function (referral) {
          console.log('referral: ' + referral.uris.join());
        });
        res.on('error', function (err) {
          console.error('error: ' + err.message);
        });
        res.on('end', function (result) {
        });
      });

    });

    for (let loopCounter = 0; !aeName && maxLoopCount > loopCounter; loopCounter++)
      deasync.sleep(waitTime);
    if (!aeName)
      throw new Error(waitTimeOutErrorMsg);
    return aeName;
  }
};

//Register an Application
//Notification endpoint: http://localhost:9000, where 9000 should be same as port
//Assign ACPs on all tenants like LwM2M, IoT.DEFAULT, MQTT etc..
Config.app = {
  username: Config.ldap.readAENameFromLdap('uid=HPE_IoT/dc-test-app,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),			//**Application Info**
  //username:"C8a20a862-25e98ac8",
  password: "password",					//**Application Info**
  host: '<DC Automation VM IP>', // --> Notification endpoint host		// ***Environment Info to be replaced here***
  port: 19000 // --> Notification endpoint port							//***This port needs to be opened at firewall 
  //username: dcTestAppAE,
  //password: 'password'
};

/* Active lwm2m 144 som*/
Config.lwm2m = {
  TLV_FORMAT: { IANA_Media_Type: 'application/vnd.oma.lwm2m+tlv', Numeric_Content_Format: '11542' },
  JSON_FORMAT: { IANA_Media_Type: 'application/vnd.oma.lwm2m+json', Numeric_Content_Format: '11543' },
  OPAQUE_FORMAT: { IANA_Media_Type: 'application/octet-stream', Numeric_Content_Format: '42' },
  INVALID_FORMAT: { IANA_Media_Type: 'application/invalid', Numeric_Content_Format: '4' },
  CBOR_FORMAT: {IANA_Media_Type: 'application/senml+cbor', Numeric_Content_Format: '112'},
  simulator: {
    name: 'lwm2m',
    path: process.cwd() + '/lwm2m/gLwDevice/', ///root/karthik/dc-tests
    process: ['-jar', process.cwd() + '/lwm2m/gLwDevice/gLwDevice.jar', 'urn:lwm2m_nosec', '<DC_IP>:15673'],		// ***Device Info*** &&  // ***Environment Info to be replaced here***  
    unsecured_ip_port: '<DC_IP>:15673',						// ***Environment Info to be replaced here***
    secured_ip_port: '<DC_IP>:15684',						// ***Environment Info to be replaced here***
    unsecured_bootstrap_ip_port: '<DC_IP>:15683',			// ***Environment Info to be replaced here***
    secured_bootstrap_ip_port: '<DC_IP>:15674'				// ***Environment Info to be replaced here***
  },
  //lwm2m NoSec device details
  // device: {
  //   name: 'lwm2m_nosec ',
  //   username: 'CF3181C4A-lwm2m_nosec', // --> AE-ID
  // },
  device: {
    name: 'lwm2m_nosec',				// ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=urn:lwm2m_nosec,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'), // --> AE-ID
  },
  device_bootstrap: {
    name: 'lwm2m_nosec',				// ***Device Info***
    //username: 'CF3181C4A-lwm2m_nosec',
    username: Config.ldap.readAENameFromLdap('uid=urn:lwm2m_nosec,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),
    bootStrapEnabled: true// --> AE-ID
  },
  //lwm2m Psk device details
  psk_device: {
    name: 'lwm2m_psk',				// ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=urn:lwm2m_psk,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),// --> AE-ID
    // username: 'C84E50E96-lwm2m_psk', 
    PSK_VALUE: '70 61 73 73 77 6f 72 64',
    PSK_IDENTITY: 'lwm2m_psk_AA'
    //PSK_AUTH_VALUE:cGFzc3dvcmQ=
  },
  psk_device_TC92: {
    name: 'TC92_lwm2m_psk',			// ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=urn:TC92_lwm2m_psk,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),// --> AE-ID
    // username: 'C84E50E96-TC92_lwm2m_psk', 
    PSK_VALUE: '70 61 73 73 77 6f 72 64',
    PSK_IDENTITY: 'TC92_lwm2m_psk_AA'
    //PSK_AUTH_VALUE:cGFzc3dvcmQ=
  },
  psk_device_TC93: {
    name: 'TC93_lwm2m_psk',			// ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=urn:TC93_lwm2m_psk,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),// --> AE-ID
    // username: 'C84E50E96-TC92_lwm2m_psk', 
    PSK_VALUE: '70 61 73 73 77 6f 72 64',
    PSK_IDENTITY: 'TC93_lwm2m_psk_AA'
    //PSK_AUTH_VALUE:cGFzc3dvcmQ=
  }
  ,
  psk_device_TC94: {
    name: 'TC94_lwm2m_psk',			// ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=urn:TC94_lwm2m_psk,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),// --> AE-ID
    // username: 'C84E50E96-TC92_lwm2m_psk', 
    PSK_VALUE: '70 61 73 73 77 6f 72 64',
    PSK_IDENTITY: 'TC94_lwm2m_psk_AA'
    //PSK_AUTH_VALUE:cGFzc3dvcmQ=
  },
  psk_device_TC95: {
    name: 'TC95_lwm2m_psk',			// ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=urn:TC95_lwm2m_psk,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),// --> AE-ID
    // username: 'C84E50E96-TC92_lwm2m_psk', 
    PSK_VALUE: '70 61 73 73 77 6f 72 64',
    PSK_IDENTITY: 'TC95_lwm2m_psk_AA'
    //PSK_AUTH_VALUE:cGFzc3dvcmQ=
  }
};

Config.mqtt = {
  topics: {
    uplink: "/oneM2M/req/%s/%s", //json
    uplinkResponse: "/oneM2M/resp/%s/%s",
    downlink: "/oneM2M/req/%s/%s",
    downlinkResponse: "/oneM2M/resp/%s/%s"
  },
  //Aligned with packet capture
  payload: {
    "to": Config.uiot.cseBase + "/%s%s",
    "op": 1,
    "pc": {
      "m2m:cin": {
        "con": "{\"data\": {\"key\": \"Karthik MQTT 1\"}}"
      }
    },
    "fr": Config.uiot.cseBase + "/%s",
    "rqi": "kar1",
    "ty": 4,
    "rt": 2
  },
  //EMQ broker address
  broker: "mqtt://<Emqx_IP>:<Emqx_PORT>",			// ***Environment Info***
  //MQTT device details
  device: {
    username: Config.ldap.readAENameFromLdap('uid=mqtt1,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),
    //password: "4730b64c",
    password: "password",					// ***Device Info***
    name: "mqtt1",							// ***Device Info***
    downlinkContainer: 'commands'
  },
  /*  invalid_device: {
    username: "C8a20a862-mqtt1",
    //password: "4730b64c",
    password: "password",
    name: "invalisggmqtt1",
    downlinkContainer: 'commands'
  },
  mismatch_device: {
    username: "mismatch",
    //password: "4730b64c",
    password: "mismatch",
    name: "mqtt1",
    downlinkContainer: 'commands'
  } */
};


Config.http = {
  device: {
    name: 'http1',							// ***Device Info***
    devname: 'http_device',     // ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=http1,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),
    devusername: Config.ldap.readAENameFromLdap('uid=http_device,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),
    password: 'password',						// ***Device Info***
    host: '<DC Automation VM IP>',			// ***Environment Info***
    port: 19001,							//***This PORT needs to be opened at firewall
    hostname: '<DC Automation VM Hostname>',				//  ***Environment Info***
    defaultPort: 80,           //**Default HTTP port
    downlinkContainer: 'commandContainer'
  },
  server: {
    url: 'http://<DC_IP>:<DC_PORT>',			// ***Environment Info***
    path: 'oneM2M-http-device-controller'
  }
};


Config.ow = {
  device: {
    name: '2018012900110323',				// ***Device Info***
    newDev: '2019073107312010',				// ***Device Info***
    username: Config.ldap.readAENameFromLdap('uid=2018012900110323,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),
    password: 'password',					// ***Device Info***
    host: '<DC Automation VM IP>',			// ***Environment Info***
    port: 19001,							//***This PORT needs to be opened at firewall
    downlinkContainer: 'DownlinkPayload',
    dpid: '104',
    customerId: '1393',
    deviceGroupId: '1395'
  },
  kafka: "<KAFKA_IP>:<KAFKA_PORT>",					// ***Environment Info***
  zookeeper: "<ZOOKEEPER_IP>:<ZOOKEEPER_PORT>",		// ***Environment Info***
  uplinkTopic: "TCOM_OW_UPLINK",
  downlinkTopic: "TCOM_OW_DOWNLINK"
  /*,
  server: {
    url: 'http://<DC_IP>:<DC_PORT>',				// ***Environment Info***
    path: 'orbiwise-device-controller'
  },
  lns: {
    port: 11300
  },
  dsm: {
    host: '15.213.51.145',
    port: 11080,
    adminCrediantials: 'Basic YWRtaW46cGFzc3dvcmQ='
  },
  dav: {
    host: '15.213.51.145',
    port: 12080
  },
  downlink_app: {
    auth: 'Basic Q0EyMzU3ODM5LTdkODY3M2FkOnBhc3N3b3Jk'
  } */
};

//lpgaz_app_2_automation - created in dsm
Config.app_TWO = { // lpgaz_app_2_automation  
  username: Config.ldap.readAENameFromLdap('uid=HPE_IoT/lpgaz_app_2_automation,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),
  password: "password",								//**Application Info**
  host: '<DC Automation VM IP>', // --> Notification endpoint host		// ***Environment Info to be replaced here***
  port: 19001, // --> Notification endpoint port						//***This port needs to be opened at firewall 
};

//Copy Gozu-san's Lwm2m simulator to same VM
Config.lpgaz = {
  JSON_FORMAT: 'application/vnd.oma.lwm2m+json',
  TLV_FORMAT: 'application/vnd.oma.lwm2m+tlv',
  PLAIN_TEXT_FORMAT: "text/plain",
  OPAQUE_FORMAT: "application/octet-stream",
  simulator: {
    name: 'gateway',
    path: process.cwd() + '/lpgaz/gLwDevice/',
    process: ['-jar', process.cwd() + '/lpgaz/gLwDevice/gLwDevice.jar', 'urn:RID:3SAY1234567000', '<DC_IP>:17683']		// ***Device Info*** && // ***Environment Info***
  },

  simulator_PSK: { // 3SAY1234567004 - PSK device and port should be - 17684
    name: 'gateway',
    path: process.cwd() + '/lpgaz/gLwDevice/',
    process: ['-jar', process.cwd() + '/lpgaz/gLwDevice/gLwDevice.jar', 'urn:RID:3SAY1234567004', '<DC_IP>:17684']		// ***Device Info*** && // ***Environment Info***
  },

  simulatorWan: {
    name: 'WAN',
    path: process.cwd() + '/lpgaz/wanDevice/',
    process: ['-jar', process.cwd() + '/lpgaz/wanDevice/gLwDevice.jar', 'urn:RID:3SAY1234567002', '<DC_IP>:17683']		// ***Device Info*** && // ***Environment Info***
  },
  //0 - gateway, others - child devices
  devices: [
    { name: 'RID:3SAY1234567000', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567000,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') },
    { name: 'RID:3SAY1234567001', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567001,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') },
    { name: 'RID:3SAY1234567002', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567002,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') },
    { name: 'RID:3SAY1234567003', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567003,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') },
    { name: 'RID:3SAY1234567004', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567004,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'), PSK_IDENTITY: "mypsk", PSK_VALUE: "62 61 72" }


  ],
  xtra_devices: [
    { name: 'RID:3SAY1234567027', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567027,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') },
    { name: 'RID:3SAY1234567028', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567028,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') },
    { name: 'RID:3SAY1234567029', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567029,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') },
    { name: 'RID:3SAY1234567030', username: Config.ldap.readAENameFromLdap('uid=urn:RID:3SAY1234567030,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org') }




  ]
};


//Copy Gozu-san's SCEF & Device simulator to this VM
Config.scef = {
  TLV_FORMAT: 'application/vnd.oma.lwm2m+tlv',
  JSON_FORMAT: 'application/vnd.oma.lwm2m+json',
  scefSimulator: {
    name: 'SCEF',
    path: '/root/karthik/nidd/gLwDevice_july17/',
    process: ['com/hpe/cmsj/gLwDevice/scefSimulator', 'localhost:5683']
  },
  provisioningInfo: {
    //Customer ID of LwM2M customer
    deviceProfileId: 114,
    customerId: 1391,
    deviceGroupId: 1392,
  },
  simulator: {
    name: 'scefDevice',
    path: '/root/karthik/nidd/gLwDevice_july17/',
    process: ['-Xmn50m', 'com/hpe/cmsj/gLwDevice/devSimulator', 'urn:dev200', 'localhost:5683'],
    encoder: 'cbor'
  },
  device: {
    name: 'dev454',
    username: 'CF3181C4A-dev454',
  },
  
  getCreateAssetPayload: function(name) {
    return {
        authNType:'NO_SECURITY',
        bstrpAuthNType: 'NO_SECURITY',
        status:'Provisioned',
        deviceProfileId: this.provisioningInfo.deviceProfileId,
        deviceAutoProvision:'true',
        resourceType:'SENSOR',
        customerId: this.provisioningInfo.customerId,
        deviceGroupId: this.provisioningInfo.deviceGroupId,
        resourceName: name,
        displayProfileId:'0',
        networkProvisionParams:{
          nidd_lwm2m:'true'
        },
        host:'urn:' + name,
        enabled:'true',
        iotParams:{
              ID: "urn:" + name,          
              TestProfile: false,        
              externalId: name + "@softbank.jp",          
              maximumPacketSize: "10840",           
              notifyOnSubscription: true,           
              supportedFeatures: "12345"     
        }
    }
  },

  getUpdateAssetPayload: function(name, configId, poa) {
    var payload = this.getCreateAssetPayload(name);
    payload.status = 'Joined';
    payload.host = poa;
    payload.iotParams.niddConfigurationId = configId;
    return payload;
  }
};


Config.coap = {
  device: {
    name: 'COAP_Asset1',					// ***Device Info*** 
    //username: 'C8a20a862-3fdd61d4', // --> AE-ID
    username: Config.ldap.readAENameFromLdap('uid=COAP_Asset1,ou=alias,ou=AuthNZ,ou=M2M,dc=UIoT,dc=org'),
    password: 'password', 				// ***Device Info*** 
    uplink_host: '<DC_IP>',						// ***Environment Info***
    uplink_port: 5683,					//***This port needs to be opened at firewall
    downlink_host: '<DC Automation VM IP>', // ***Environment Info to be replaced here***
    downlink_port: 16783,					//***This port needs to be opened at firewall
    downlink_container: 'commandContainer1'
  }
};



module.exports = Config;
