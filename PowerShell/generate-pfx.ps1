$FQDN = "devx.qsa.se"
$CertPassword = ConvertTo-SecureString -String “apa123” -Force –AsPlainText
Get-Command -Module PKI
$NewCert = New-SelfSignedCertificate -DnsName $FQDN -CertStoreLocation cert:\LocalMachine\My
$ThumbPrint = $NewCert.Thumbprint
Export-PfxCertificate -Cert cert:\LocalMachine\My\$ThumbPrint  -FilePath C:\$FQDN.pfx -Password $CertPassword
Export-Certificate -Cert Cert:\LocalMachine\My\$ThumbPrint -FilePath C:\$FQDN.cer
#New-SelfSignedCertificate -DnsName adfs1.contoso.com,web_gw.contoso.com,enterprise_reg.contoso.com -CertStoreLocation cert:\LocalMachine\My
#New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname *.contoso.com
