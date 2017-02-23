The SFTF.PS project now has 7 main scripts, each named after a specific task.  You can click on any of the script names in the following table to get instructions on each.

| Script | Purpose |
| --- | --- |
| [01 - Create-SelfSignedCert.ps1](markdown/01.md) | Creates a self signed certificate to use to secure the Service Fabric cluster |
| [02 - CreateKeyVault.ps1](markdown/02.md) | Creates a new resource group and a key vault in that group |
| [03 - Add-KeyToKeyVault.ps1](markdown/03.md) | Adds a certificate to your key vault as a secret |
| [04 - Create-SecureServiceFabricCluster.ps1](markdown/04.md) | Creates a self signed certificate to use to secure the Service Fabric cluster |
| [05 - Create-Validate-SecureServiceFabricCluster.ps1](markdown/05.md) | Connects to your cluster to verify it is operational |
| [06 - Deploy-Application.ps1](markdown/06.md) | Deploys an application to your cluster |
| [07 - Configure-AADForAuth.ps1](markdown/07.md) | Configures apps and service principals to secure your cluster with AAD |

There are 6 self signed certificates available for your use the the _certs_ folder of the SFTF.PS project.  The following table outlines each and their respective thumbprint (you will need those):

| Filename | Thumbprint |
| --- | --- |
| mysfcluster1.pxf | `812508463AE35AF784956315D3414DF1854CF8A6` |
| mysfcluster2.pxf | `015B7EA8023C0DEB2FE21280AE6F6425D0B557DC` |
| mysfcluster3.pxf | `3789E0A881409BC5283C326BE980F23D84FE9104` |
| mysfcluster4.pxf | `C6C89C4D8F01CA174233734568828E84BAF56499` |
| mysfcluster5.pxf | `279B5F1101838B70825B0885FEC503064159C862` |
| mysfcluster6.pxf | `5BF3305C59F5BB830A92C4D7F5BDC97C70A845B2` |



