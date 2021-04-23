unit PI.JWT;

// VERY basic JWT implementation, purely for Google OAuth2

interface

uses
  System.NetEncoding, System.SysUtils;

type
  TGoogleJWTHeader = record
    Algorithm: string;
    TokenType: string;
    function Generate(const AEncoding: TNetEncoding): string;
  end;

  TGoogleJWTClaim = record
    Iss: string;
    Scope: string;
    Aud: string;
    function Generate(const AEncoding: TNetEncoding): string;
  end;

  TGoogleJWT = record
    Header: TGoogleJWTHeader;
    Claim: TGoogleJWTClaim;
    function SignSHA26WithRSA(const APrivateKey: TBytes; const AData: TBytes): TBytes;
    function GenerateToken(const APrivateKey: string): string;
  end;

implementation

uses
  // RTL
  System.Hash, System.DateUtils,
  // Grijjy
  OpenSSL.Api_11,
  // PushIt
  PI.Consts;

{ TGoogleJWTHeader }

function TGoogleJWTHeader.Generate(const AEncoding: TNetEncoding): string;
begin
  Result := AEncoding.Encode(Format('{"alg":"%s", "typ":"%s"}', [Algorithm, TokenType]));
end;

{ TGoogleJWTClaim }

function TGoogleJWTClaim.Generate(const AEncoding: TNetEncoding): string;
var
  LIAT, LExp: Int64;
  LJSON: string;
begin
  LIAT := DateTimeToUnix(Now, False);
  LExp := DateTimeToUnix(IncHour(Now, 1), False);
  LJSON := Format('{"iss":"%s", "scope":"%s", "aud":"%s", "exp":%d, "iat":%d}', [Iss, Scope, Aud, LExp, LIAT]);
  Result := AEncoding.Encode(LJSON);
end;

{ TGoogleJWT }

function TGoogleJWT.GenerateToken(const APrivateKey: string): string;
var
  LBase64: TBase64Encoding;
  LSignable: string;
  LSignature: TBytes;
begin
  Header.Algorithm := 'RS256';
  Header.TokenType := 'JWT';
  Claim.Aud := cFCMJWTAudience;
  Claim.Scope := cFCMJWTScopes;
  LBase64 := TBase64Encoding.Create(0, '');
  try
    LSignable := Header.Generate(LBase64) + '.' + Claim.Generate(LBase64);
    LSignature := SignSHA26WithRSA(TEncoding.UTF8.GetBytes(APrivateKey), TEncoding.UTF8.GetBytes(LSignable));
    Result := LSignable + '.' + LBase64.EncodeBytesToString(LSignature);
  finally
    LBase64.Free;
  end;
end;

function TGoogleJWT.SignSHA26WithRSA(const APrivateKey: TBytes; const AData: TBytes): TBytes;
var
  LPrivateKeyRef: PBIO;
  LPrivateKey: PEVP_PKEY;
  LContext: PEVP_MD_CTX;
  SHA256: PEVP_MD;
  LSize: NativeUInt;
begin
	LPrivateKeyRef := BIO_new_mem_buf(@APrivateKey[0], Length(APrivateKey));
  try
    LPrivateKey := PEM_read_bio_PrivateKey(LPrivateKeyRef, nil, nil, nil);
    try
      LContext := EVP_MD_CTX_create;
      try
        SHA256 := EVP_sha256;
        if (EVP_DigestSignInit(LContext, nil, SHA256, nil, LPrivateKey) > 0) and
          (EVP_DigestUpdate(LContext, @AData[0], Length(AData)) > 0) and
          (EVP_DigestSignFinal(LContext, nil, LSize) > 0) then
        begin
          SetLength(Result, LSize);
          if EVP_DigestSignFinal(LContext, @Result[0], LSize) = 0 then
            SetLength(Result, 0);
        end;
      finally
        EVP_MD_CTX_destroy(LContext);
      end;
    finally
      EVP_PKEY_free(LPrivateKey);
    end;
  finally
	  BIO_free(LPrivateKeyRef);
  end;
end;

end.
