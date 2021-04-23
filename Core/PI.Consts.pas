unit PI.Consts;

interface

const
  cFCMLegacyHTTPSendURL = 'https://fcm.googleapis.com/fcm/send';
  cFCMHTTPv1SendURL = 'https://fcm.googleapis.com/v1/projects/%s/messages:send'; // eg https://fcm.googleapis.com/v1/projects/delphi-worlds-test/messages:send
  cFCMJWTScopes = 'https://www.googleapis.com/auth/firebase.messaging';  // https://developers.google.com/identity/protocols/oauth2/scopes
  cFCMJWTAudience = 'https://oauth2.googleapis.com/token'; // 'https://www.googleapis.com/oauth2/v4/token';

implementation

end.
