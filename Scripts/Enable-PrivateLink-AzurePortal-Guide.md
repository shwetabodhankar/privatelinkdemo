# Azure Portal Guide: Enable Private Link for Key Vault

This guide provides step-by-step instructions to enable Private Link access to Azure Key Vault using the Azure Portal.

**Environment**: rg-test-ntt (Public Demo Environment)  
**Key Vault**: myapp-kv-8700  
**Web App**: myapp-web-5233  
**Goal**: Secure Key Vault access using Private Endpoint

---

## Architecture Overview

```
Internet
   │
   └─> App Service (myapp-web-5233)
          │
          └─> VNet Integration (subnet-app-integration)
                 │
                 └─> Routes through VNet
                        │
                        └─> Private Endpoint (10.0.2.x)
                               │
                               └─> Key Vault (myapp-kv-8700)
                                     [Public access: Disabled or Selected IPs]
```

---

## Why Do We Need Private Link?

### The Problem with Public Endpoints

By default, Azure services like Key Vault, SQL Database, and Storage Accounts are accessible via **public endpoints** over the internet:

```
Your App → Internet → Azure Service Public IP → Key Vault
                     (Anyone can attempt connection)
```

**Security Risks:**
- 🔓 Service is exposed to the entire internet (even with firewall rules)
- 🌐 Traffic traverses the public internet (less secure)
- 🎯 Public endpoints are targets for attacks (DDoS, brute force)
- 📊 Harder to audit and control network traffic

### The Solution: Private Link

Private Link creates a **private endpoint** inside your Virtual Network with a private IP address:

```
Your App → VNet → Private Endpoint (10.0.2.x) → Key Vault
                  (Completely private, no internet)
```

**Benefits:**
- ✅ Service is accessible only from your VNet (or peered VNets)
- ✅ Traffic never leaves Azure backbone network
- ✅ No exposure to the public internet
- ✅ Simplified network security (NSGs, firewall rules)
- ✅ Meets compliance requirements (PCI-DSS, HIPAA, SOC2)

### Real-World Scenarios

#### Scenario 1: Financial Services
**Requirement**: Customer data in Key Vault must not be accessible from the internet.

**Solution**: 
- Deploy Private Endpoint for Key Vault
- Disable public access completely
- Only VNet-integrated applications can access secrets

**Result**: Meets PCI-DSS requirement for private network segmentation

---

#### Scenario 2: Multi-Tier Application
**Architecture**: 
- Web App (public-facing)
- API App (internal)
- SQL Database (internal)
- Key Vault (internal)

**Solution**:
- Web App and API App use VNet integration
- SQL Database and Key Vault have private endpoints
- All internal communication stays on private network

**Result**: Public users access web app, but backend services are completely isolated

---

#### Scenario 3: Hybrid Cloud
**Setup**: 
- On-premises data center connected via ExpressRoute
- Azure resources need to be accessed from on-premises

**Solution**:
- Create private endpoints for Azure services
- VNet peers with ExpressRoute gateway
- On-premises systems access Azure services via private IPs

**Result**: Seamless private connectivity between on-premises and Azure

---

## Components Overview

### 1. Virtual Network (VNet)

**What it is**: A logically isolated network in Azure where you deploy your resources.

**Why you need it**: 
- Foundation for private networking
- Required for private endpoints and VNet integration
- Provides network segmentation and isolation

**Think of it as**: Your own private data center network in the cloud

**Key Concepts**:
- **Address Space**: Range of IP addresses (e.g., 10.0.0.0/16 = 65,536 IPs)
- **Subnets**: Smaller segments within the VNet (e.g., 10.0.1.0/24 = 256 IPs)
- **Delegation**: Granting a subnet to a specific Azure service

**Example**:
```
VNet: 10.0.0.0/16
  ├─ subnet-app-integration: 10.0.1.0/24 (for App Service)
  ├─ subnet-private-endpoints: 10.0.2.0/24 (for Key Vault, SQL)
  └─ subnet-general: 10.0.3.0/24 (for VMs, other resources)
```

---

### 2. Private Endpoint

**What it is**: A network interface with a private IP address that connects to an Azure service.

**Why you need it**: 
- Makes Azure services (Key Vault, SQL) accessible via private IP
- Eliminates exposure to the public internet
- Enables private connectivity

**Think of it as**: A "private door" into your Key Vault that only exists in your VNet

**How it works**:
1. Creates a network interface (NIC) in your subnet
2. Assigns a private IP (e.g., 10.0.2.5)
3. Maps your service's FQDN to the private IP
4. Routes traffic through Azure backbone instead of internet

**Example**:
```
Before: myapp-kv-8700.vault.azure.net → 20.x.x.x (public IP)
After:  myapp-kv-8700.vault.azure.net → 10.0.2.5 (private IP)
```

**Use Cases**:
- Securing Key Vault access from App Service
- Connecting to SQL Database privately
- Accessing Storage Accounts without internet exposure

---

### 3. Firewall Configuration

**What it is**: Network rules that control which IP addresses can access your Azure service.

**Why you need it**: 
- Block unwanted public access
- Allow specific IPs (your office, home)
- Configure exceptions for Azure services

**Think of it as**: A security guard at the door checking IDs

**Configuration Options**:

**Option A - Completely Private**:
- Public access: **Disabled**
- Result: Only private endpoint works, no internet access

**Use when**: Production environments requiring maximum security

---

**Option B - Hybrid (Recommended)**:
- Public access: **Selected networks**
- Allowed IPs: Your IP address, office network
- Exception: Azure trusted services

**Use when**: 
- Development/testing
- Need portal access to view secrets
- Still want private endpoint for app traffic

---

**Option C - Fully Public (Default)**:
- Public access: **All networks**
- Result: Accessible from anywhere (with authentication)

**Use when**: 
- Initial development
- No compliance requirements
- Simplified access

**Example Configuration**:
```
Key Vault Firewall Rules:
  ✅ Allow: 10.0.0.0/16 (VNet)
  ✅ Allow: 203.0.113.50 (Your Office IP)
  ✅ Allow: Azure trusted services
  ❌ Deny: All other internet traffic
```

---

### 4. VNet Integration

**What it is**: Connecting your App Service to a VNet so it can access private resources.

**Why you need it**: 
- App Service runs on shared infrastructure (not in your VNet by default)
- VNet integration "joins" your app to your private network
- Enables access to private endpoints, VMs, on-premises resources

**Think of it as**: Plugging your app into your private network

**How it works**:
1. Creates a connection from App Service to a subnet (delegated to Microsoft.Web/serverFarms)
2. Routes outbound traffic through the VNet
3. App can now reach private IP addresses (10.0.x.x)

**Regional vs Gateway VNet Integration**:
- **Regional** (recommended): Faster, no gateway needed, same region as VNet
- **Gateway**: For cross-region or older setups, requires VPN gateway

**Route All Setting**:
- **Off**: Only VNet address space goes through VNet
- **On**: ALL outbound traffic (including internet) goes through VNet

**Use when Route All = On**:
- Accessing private endpoints
- Need to control all outbound traffic
- Applying NSG rules to app traffic

**Example Flow**:
```
Without VNet Integration:
  App Service → Internet → Key Vault Public Endpoint

With VNet Integration:
  App Service → VNet (10.0.1.x) → Private Endpoint (10.0.2.x) → Key Vault
```

---

### 5. Private DNS Zone

**What it is**: A DNS zone that resolves service names to private IP addresses within your VNet.

**Why you need it**: 
- Your app uses the public FQDN (myapp-kv-8700.vault.azure.net)
- DNS needs to return the private IP (10.0.2.x) instead of public IP
- Without it, traffic would still go to public endpoint

**Think of it as**: A private phone book that translates names to private numbers

**How it works**:
1. Private DNS zone is created: `privatelink.vaultcore.azure.net`
2. A DNS record is added: `myapp-kv-8700` → `10.0.2.5`
3. Zone is linked to your VNet
4. Apps in VNet query DNS and get private IP

**Example Resolution**:
```
From Internet:
  myapp-kv-8700.vault.azure.net → 20.x.x.x (public IP)

From VNet (with Private DNS):
  myapp-kv-8700.vault.azure.net → 10.0.2.5 (private IP)
```

**Key DNS Zones by Service**:
| Service | Private DNS Zone |
|---------|------------------|
| Key Vault | privatelink.vaultcore.azure.net |
| SQL Database | privatelink.database.windows.net |
| Blob Storage | privatelink.blob.core.windows.net |
| File Storage | privatelink.file.core.windows.net |

---

## Complete Workflow Example

### Scenario: Securing a Production Web App

**Initial State**:
```
Web App (myapp-web-5233)
   │
   └─> Internet (public)
         │
         └─> Key Vault Public IP (anyone can attempt)
```

**Step-by-Step Transformation**:

**Step 1: Create VNet** → Builds the private network foundation
```
VNet: 10.0.0.0/16 created
```

**Step 2: Create Private Endpoint** → Opens private door to Key Vault
```
Private Endpoint (10.0.2.5) → Key Vault
```

**Step 3: Configure DNS** → Makes name resolution work privately
```
myapp-kv-8700.vault.azure.net → 10.0.2.5
```

**Step 4: Configure Firewall** → Blocks public access
```
Key Vault: Public access = Disabled
```

**Step 5: Enable VNet Integration** → Connects app to VNet
```
Web App → VNet (10.0.1.x)
```

**Final State**:
```
Web App (10.0.1.x in VNet)
   │
   └─> VNet (private)
         │
         └─> Private Endpoint (10.0.2.5)
               │
               └─> Key Vault (no public access)
```

**Result**: 
- ✅ All traffic stays on Azure backbone
- ✅ Zero internet exposure
- ✅ Meets compliance requirements
- ✅ Improved security posture

---

## Phase 1: Create Virtual Network

### Step 1: Navigate to Virtual Networks
1. Open **Azure Portal** (portal.azure.com)
2. Search for **"Virtual networks"** in top search bar
3. Click **"+ Create"**

### Step 2: Create VNet - Basics Tab
- **Subscription**: (your subscription)
- **Resource group**: `rg-test-ntt`
- **Virtual network name**: `vnet-test-ntt`
- **Region**: `West US`
- Click **"Next: IP Addresses"**

### Step 3: Create VNet - IP Addresses Tab

**Configure Address Space:**
- **IPv4 address space**: `10.0.0.0/16`

**Create 3 Subnets** - Click **"+ Add subnet"** for each:

#### Subnet 1 - App Integration
- **Subnet name**: `subnet-app-integration`
- **Subnet address range**: `10.0.1.0/24`
- **Delegate subnet to a service**: `Microsoft.Web/serverFarms`
- Click **"Add"**

> ℹ️ **Why**: This subnet will be used for App Service VNet integration. Delegation is required.

#### Subnet 2 - Private Endpoints
- **Subnet name**: `subnet-private-endpoints`
- **Subnet address range**: `10.0.2.0/24`
- **Private endpoint network policy**: `Disabled` ⚠️ **Important!**
- Click **"Add"**

> ℹ️ **Why**: This subnet hosts the private endpoint for Key Vault.

#### Subnet 3 - General (Optional)
- **Subnet name**: `subnet-general`
- **Subnet address range**: `10.0.3.0/24`
- Click **"Add"**

**Finish Creation:**
- Click **"Review + create"**
- Click **"Create"**
- ⏱️ Wait for deployment (~1-2 minutes)

---

## Phase 2: Create Private Endpoint for Key Vault

### Step 4: Navigate to Key Vault
1. Azure Portal → Search **"myapp-kv-8700"**
2. Click on your Key Vault

### Step 5: Access Private Endpoint Settings
In the **left menu**:
- Scroll to **"Settings"** section
- Click **"Networking"**

You'll see two tabs:
- **Firewalls and virtual networks**
- **Private endpoint connections**

### Step 6: Create Private Endpoint

1. Click **"Private endpoint connections"** tab
2. Click **"+ Create"** (or **"+ Private endpoint"**)

#### Page 1 - Basics
- **Resource group**: `rg-test-ntt`
- **Name**: `pe-myapp-kv-8700`
- **Network Interface Name**: `nic-pe-myapp-kv-8700` (auto-filled)
- **Region**: `West US`
- Click **"Next: Resource"**

#### Page 2 - Resource
- **Connection method**: `Connect to an Azure resource in my directory` ✅
- **Subscription**: (your subscription)
- **Resource type**: `Microsoft.KeyVault/vaults`
- **Resource**: `myapp-kv-8700` (select from dropdown)
- **Target sub-resource**: `vault` (only option)
- Click **"Next: Virtual Network"**

#### Page 3 - Virtual Network
- **Virtual network**: `vnet-test-ntt`
- **Subnet**: `subnet-private-endpoints (10.0.2.0/24)`
- **Private IP configuration**: `Dynamically allocate IP address` ✅
- **Application security group**: None

**Integrate with private DNS zone:** ⚠️ **Critical**
- **Integrate with private DNS zone**: `Yes` (toggle ON)
- **Subscription**: (your subscription)
- **Resource group**: `rg-test-ntt`
- **Private DNS Zone**: Auto-creates `privatelink.vaultcore.azure.net`

**Finish:**
- Click **"Next: Tags"**
- Click **"Next: Review + create"**
- Click **"Create"**
- ⏱️ Wait for deployment (~2-3 minutes)

---

## Phase 3: Configure Key Vault Network Access

### Step 7: Update Key Vault Firewall Rules

1. Return to **Key Vault** (`myapp-kv-8700`)
2. Go to **Networking**
3. Click **"Firewalls and virtual networks"** tab

Current settings will show:
- **Public access**: Enabled from all networks (default)

### Step 8: Configure Network Access

**Choose Your Security Model:**

#### Option A - Strict (Block All Public Access) 🔒

**Use when**: Production environment with no portal access needed

- **Public network access**: Select **"Disabled"**

⚠️ **Warning**: 
- You'll lose Azure Portal access to secrets
- Only VNet-connected resources can access
- Good for production security

---

#### Option B - Hybrid (Recommended for Testing) 🔐

**Use when**: Testing setup or need portal access

- **Public network access**: Select **"Enabled from selected virtual networks and IP addresses"**

**Firewall Configuration:**
- ✅ Check **"Add your client IPv4 address"** (adds your current IP automatically)
- Or manually add your IP in **"Address range"** field

**Exceptions:**
- ✅ Check **"Allow trusted Microsoft services to bypass this firewall"**

> ℹ️ **Why**: This allows App Service and other Azure services to access even when public access is restricted

**Apply Settings:**
- Click **"Apply"** at the bottom
- ⏱️ Wait ~30 seconds for changes to propagate

---

## Phase 4: Enable VNet Integration for Web App

### Step 9: Navigate to Web App
1. Azure Portal → Search **"myapp-web-5233"**
2. Click on your Web App

### Step 10: Access Networking Settings

In **left menu**:
- Scroll to **"Settings"** section
- Click **"Networking"**

You'll see a dashboard with:
- **Inbound Traffic** (left box)
- **Outbound Traffic** (right box)

### Step 11: Add VNet Integration

In the **Outbound Traffic** section:
- Click **"VNet integration"** box
- Click **"+ Add VNet"** (blue button)

**Configuration Panel:**
- **Virtual Network**: Select `vnet-test-ntt`
- **Subnet**: Select `subnet-app-integration (10.0.1.0/24)`

> ⚠️ **If subnet is grayed out**: The subnet must be delegated to `Microsoft.Web/serverFarms` (check Phase 1, Step 3)

- Click **"Connect"** (or **"OK"**)
- ⏱️ Wait ~1 minute for configuration

**Verify Connection:**
You should see:
- ✅ Status: **Connected**
- VNet: `vnet-test-ntt`
- Subnet: `subnet-app-integration`

### Step 12: Enable Route All Traffic

Still in **Networking** → **VNet integration**:
- Look for **"Route All"** toggle or checkbox
- Toggle to **"On"** or check the box

> ℹ️ **Why**: This ensures ALL outbound traffic (including Key Vault calls) goes through VNet and can reach the private endpoint

---

## Phase 5: Verify Configuration

### Step 13: Check Private Endpoint Connection

1. Go back to **Key Vault** (`myapp-kv-8700`)
2. **Networking** → **Private endpoint connections** tab

**What you should see:**
| Name | Connection State | Private IP | FQDN |
|------|------------------|------------|------|
| pe-myapp-kv-8700 | ✅ Approved | 10.0.2.x | myapp-kv-8700.privatelink.vaultcore.azure.net |

> ⚠️ **If state is "Pending"**: Something went wrong. Delete and recreate the private endpoint.

### Step 14: Verify DNS Configuration

1. Go to **Private endpoint** resource (`pe-myapp-kv-8700`)
2. Click **"DNS configuration"** in left menu

**What you should see:**
- **FQDN**: `myapp-kv-8700.vault.azure.net`
- **Private IP Address**: `10.0.2.x` (something in 10.0.2.0/24 range)
- **DNS Zone**: `privatelink.vaultcore.azure.net`

### Step 15: Check DNS Zone Link

1. Go to **Resource Group** (`rg-test-ntt`)
2. Find resource: `privatelink.vaultcore.azure.net` (Type: Private DNS zone)
3. Click it
4. Click **"Virtual network links"** in left menu

**What you should see:**
| Link name | Virtual network | Registration |
|-----------|----------------|--------------|
| (auto-generated) | vnet-test-ntt | Disabled |

> ℹ️ **Why**: This links the DNS zone to your VNet so resources inside can resolve the private IP

### Step 16: Restart Web App

1. Go to **Web App** (`myapp-web-5233`)
2. Click **"Restart"** at the top toolbar
3. Click **"Yes"** to confirm
4. ⏱️ Wait ~30-60 seconds

### Step 17: Test the Application

**Test via Portal:**
1. In Web App, click **"Browse"** at top
2. Or manually open: `https://myapp-web-5233.azurewebsites.net`

**What to verify:**
- ✅ Home page loads successfully
- ✅ Key Vault secrets display on home page (ApplicationTitle, WelcomeMessage, etc.)
- ✅ No errors about Key Vault access denied

**Expected Behavior:**
- Traffic now flows: App Service → VNet → Private Endpoint → Key Vault
- No traffic goes over public internet

---

## Troubleshooting

### Issue: Web App Shows HTTP 500 Error

**Check 1: VNet Integration Status**
- Web App → Networking → VNet integration
- Should show: **"Connected"** with green checkmark
- **Route All**: Should be **ON**

**Fix**: If not connected, repeat Phase 4

---

**Check 2: Private Endpoint State**
- Key Vault → Networking → Private endpoint connections
- State should be: **"Approved"** (green)
- If "Pending" (yellow), connection failed

**Fix**: Delete private endpoint and recreate (Phase 2)

---

**Check 3: DNS Resolution**
- Go to Web App → Development Tools → **Console**
- Run: `nslookup myapp-kv-8700.vault.azure.net`
- Should return private IP (10.0.2.x), not public IP

**Fix**: Check DNS zone link (Step 15)

---

### Issue: Can't Access Key Vault in Portal

**Symptom**: "Operation is not permitted" when viewing secrets

**Cause**: Public access is disabled, and your IP is not whitelisted

**Fix**:
1. Key Vault → Networking → Firewalls
2. Add your client IP address
3. Or temporarily enable "Enabled from all networks" for admin tasks

---

### Issue: Private Endpoint DNS Not Resolving

**Check DNS Zone Configuration:**
1. Resource Group → `privatelink.vaultcore.azure.net`
2. Virtual network links → Should see `vnet-test-ntt`
3. If missing, add link:
   - Click **"+ Add"**
   - Name: `link-vnet-test-ntt`
   - Virtual network: `vnet-test-ntt`
   - Click **"OK"**

---

### Issue: App Can Connect Publicly But Not via Private Endpoint

**Check Route All Setting:**
- Web App → Networking → VNet integration
- Ensure **"Route All"** is **enabled**

**Fix**: If disabled, enable it and restart the app

---

## Validation Checklist

Use this checklist to verify everything is working:

- [ ] VNet created with 3 subnets
- [ ] Private endpoint created for Key Vault
- [ ] Private DNS zone `privatelink.vaultcore.azure.net` exists
- [ ] DNS zone is linked to VNet
- [ ] Private endpoint shows "Approved" status
- [ ] Web App VNet integration shows "Connected"
- [ ] "Route All" is enabled on Web App
- [ ] Key Vault firewall configured (disabled or selected networks)
- [ ] Web App restarted after configuration
- [ ] Application loads successfully
- [ ] Home page displays Key Vault secrets

---

## Network Flow Diagram

### Before Private Link:
```
App Service (myapp-web-5233)
      │
      └─> Internet (Public)
            │
            └─> Key Vault Public Endpoint
                  myapp-kv-8700.vault.azure.net
                  (Public IP)
```

### After Private Link:
```
App Service (myapp-web-5233)
      │
      └─> VNet Integration (subnet-app-integration: 10.0.1.x)
            │
            └─> Azure Backbone Network (Private)
                  │
                  └─> Private Endpoint (subnet-private-endpoints: 10.0.2.x)
                        │
                        └─> Key Vault Private Connection
                              myapp-kv-8700.vault.azure.net → 10.0.2.x
                              (Private IP, no internet exposure)
```

---

## Security Benefits

✅ **Traffic Isolation**: All communication stays on Azure backbone  
✅ **No Internet Exposure**: Key Vault not accessible from public internet (if disabled)  
✅ **Compliance**: Meets requirements for private connectivity  
✅ **Network Control**: Can apply NSG rules to private endpoint subnet  
✅ **Audit Trail**: All access goes through defined network path  

---

## Cost Considerations

💰 **Costs Incurred:**
- **Private Endpoint**: ~$0.01/hour (~$7.30/month)
- **Data Processing**: ~$0.01/GB for inbound data
- **Private DNS Zone**: ~$0.50/month
- **VNet**: Free (no charge for VNet itself)

**Total Estimated**: ~$8-10/month for private link setup

---

## Next Steps

Once Key Vault is configured with Private Link, you can repeat the same process for:

1. **SQL Server Private Link**
   - Target sub-resource: `sqlServer`
   - DNS zone: `privatelink.database.windows.net`

2. **Storage Account Private Link** (if needed)
   - Target sub-resource: `blob`, `file`, `table`, or `queue`
   - DNS zone: `privatelink.blob.core.windows.net`

3. **Full Network Isolation**
   - Configure Network Security Groups (NSGs)
   - Add Azure Firewall for outbound filtering
   - Implement Azure Policy for compliance

---

## Reference Links

- [Azure Private Link Documentation](https://learn.microsoft.com/azure/private-link/)
- [Key Vault Private Endpoint](https://learn.microsoft.com/azure/key-vault/general/private-link-service)
- [App Service VNet Integration](https://learn.microsoft.com/azure/app-service/overview-vnet-integration)
- [Private DNS Zones](https://learn.microsoft.com/azure/dns/private-dns-overview)

---

**Document Version**: 1.0  
**Last Updated**: May 8, 2026  
**Environment**: rg-test-ntt (Public Demo)  
