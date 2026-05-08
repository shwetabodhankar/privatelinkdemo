# Azure Portal Guide: Enable Private Link for SQL Database

This guide provides step-by-step instructions to enable Private Link access to Azure SQL Database using the Azure Portal.

**Environment**: rg-test-ntt (Public Demo Environment)  
**SQL Server**: myapp-sql-3216  
**SQL Database**: SampleDB  
**Web App**: myapp-web-5233  
**Goal**: Secure SQL Database access using Private Endpoint

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
                               └─> SQL Database (myapp-sql-3216/SampleDB)
                                     [Public access: Disabled or Selected IPs]
```

---

## Why Do We Need Private Link for SQL Database?

### The Problem with Public Endpoints

By default, Azure SQL Database is accessible via **public endpoints** over the internet:

```
Your App → Internet → Azure SQL Public IP → SQL Database
                     (Exposed to internet attacks)
```

**Security Risks:**
- 🔓 SQL Server is exposed to the entire internet (even with firewall rules)
- 🌐 Database traffic traverses the public internet
- 🎯 SQL endpoints are prime targets for attacks (SQL injection attempts, brute force)
- 📊 Data exfiltration risks if credentials are compromised
- ⚖️ May not meet compliance requirements (PCI-DSS, HIPAA, GDPR)

### The Solution: Private Link for SQL

Private Link creates a **private endpoint** inside your Virtual Network with a private IP address:

```
Your App → VNet → Private Endpoint (10.0.2.x) → SQL Database
                  (Completely private, no internet)
```

**Benefits:**
- ✅ Database is accessible only from your VNet (or peered VNets)
- ✅ Traffic never leaves Azure backbone network
- ✅ No exposure to the public internet
- ✅ Eliminates need for IP allowlisting
- ✅ Simplified network security (NSGs, firewall rules)
- ✅ Meets compliance requirements (PCI-DSS, HIPAA, SOC2, GDPR)
- ✅ Protects against DDoS and brute force attacks

### Real-World Scenarios

#### Scenario 1: E-Commerce Platform
**Requirement**: Customer payment data in SQL Database must not be accessible from the internet.

**Solution**: 
- Deploy Private Endpoint for SQL Database
- Disable public access completely
- Only VNet-integrated web apps can query database

**Result**: Meets PCI-DSS requirement 1.3 (no direct public access to cardholder data)

---

#### Scenario 2: Healthcare Application
**Architecture**: 
- Web App (patient portal)
- API App (internal services)
- SQL Database (patient records - PHI data)

**Solution**:
- Both apps use VNet integration
- SQL Database has private endpoint only
- All PHI data stays on private network

**Result**: HIPAA compliant - PHI never traverses public internet

---

#### Scenario 3: Financial Services
**Setup**: 
- Multi-region deployment
- On-premises data center connected via ExpressRoute
- Azure SQL Database for transaction data

**Solution**:
- Private endpoints for SQL Database in each region
- ExpressRoute connection to VNet
- On-premises apps access via private network

**Result**: Zero exposure to public internet, reduced latency

---

## Understanding Current SQL Database Access (Before Private Link)

Before configuring Private Link, let's understand how your App Service currently accesses SQL Database.

### Current Configuration

Navigate to your SQL Server → **Networking** → **Public access** tab.

You'll see:
- ✅ **"Public network access"**: Enabled
- ✅ **Firewall rule**: "AllowAzureServices" (0.0.0.0)

### How App Service Accesses SQL Database Today

Your App Service can access SQL Database because of the **"Allow Azure services"** firewall rule:

```
App Service (myapp-web-5233)
    ↓ Uses Managed Identity
    ↓ Firewall allows 0.0.0.0 (Azure services)
    ↓ Authenticates via Azure AD
    → SQL Database ✅ Access Allowed
```

**What does "Allow Azure services" (0.0.0.0) mean?**
- Any Azure service can attempt to connect
- Authentication still required (managed identity)
- Traffic goes over public internet
- Not limited to YOUR Azure services

### Current State vs. After Private Link

| Aspect | Current (Public + Firewall) | After Private Link |
|--------|----------------------------|-------------------|
| **App Service Access** | ✅ Allowed (firewall rule) | ✅ Allowed (private network) |
| **Other Azure Services** | ✅ Can attempt connection | ❌ Blocked (unless in VNet) |
| **Internet/Hackers** | ⚠️ Can reach endpoint | ❌ Completely blocked |
| **Traffic Path** | ⚠️ Public internet | ✅ Private Azure backbone |
| **DNS Resolution** | Public IP | Private IP (10.0.2.x) |
| **Attack Surface** | High (internet-facing) | Low (VNet-only) |
| **Security Level** | Good | Excellent |

### The Key Difference

**Current Setup:**
```
App Service → Public Internet → SQL Firewall Check → SQL Database
              (Exposed to scanning/attacks)
```

**After Private Link:**
```
App Service → VNet Integration → Private Network → Private Endpoint → SQL Database
              (No internet involvement - isolated network)
```

### What We'll Change

After completing this guide, you'll:
1. ✅ Create Private Endpoint for SQL Database
2. ✅ Disable public network access (or restrict to your IP only)
3. ❌ Remove "AllowAzureServices" firewall rule
4. ✅ Force ALL access through Private Endpoint only

**Result:** Only resources in your VNet can reach SQL Database - nothing else! 🔒

---

## Components Overview

### 1. Virtual Network (VNet)

**What it is:** Your private network in Azure (like your own data center network)

**Why you need it:** Private endpoints must exist inside a VNet

**Key Concepts:**
- **Address Space**: Range of IP addresses (e.g., 10.0.0.0/16 = 65,536 IPs)
- **Subnets**: Smaller segments within the VNet (e.g., 10.0.1.0/24 = 256 IPs)

**Example:**
```
VNet: 10.0.0.0/16
  ├─ subnet-app-integration: 10.0.1.0/24 (for App Service VNet integration)
  └─ subnet-private-endpoints: 10.0.2.0/24 (for SQL private endpoint)
```

---

### 2. Private Endpoint for SQL Database

**What it is:** A network interface with a private IP inside your VNet that connects to SQL Database

**How it works:**
- Creates a private IP (e.g., 10.0.2.5) in your subnet
- Maps to your SQL Database (myapp-sql-3216.database.windows.net)
- DNS resolves SQL FQDN to private IP instead of public IP

**Before Private Endpoint:**
```
myapp-sql-3216.database.windows.net → 20.40.50.60 (public IP)
```

**After Private Endpoint:**
```
myapp-sql-3216.database.windows.net → 10.0.2.5 (private IP in your VNet)
```

**Use Cases:**
- Block all internet access to database
- Access database from on-premises via ExpressRoute/VPN
- Multi-tier app architecture with private backend

---

### 3. SQL Server Network Configuration

**What it is:** Firewall and public access controls for SQL Server

**Three Configuration Options:**

#### Option 1: Completely Private (Production)
```
Public network access: Disabled
Firewall rules: None
Result: Only Private Endpoint works
```
**Use case:** Maximum security, production workloads, compliance requirements

#### Option 2: Hybrid (Testing/Development)
```
Public network access: Enabled from selected virtual networks
Firewall rules: Your IP address (for Azure Portal access)
Private endpoint: Available (preferred route)
Result: Private endpoint for app, public for portal/admin
```
**Use case:** Testing, development, need Azure Portal access

#### Option 3: Fully Public (Not recommended after Private Link)
```
Public network access: Enabled from all networks
Firewall rules: 0.0.0.0 (Allow Azure services)
Result: Both public and private work
```
**Use case:** Migration period, backward compatibility

**Recommendation**: Start with Option 2 for testing, move to Option 1 for production

---

### 4. VNet Integration for App Service

**What it is:** Connects your App Service to your VNet

**How it works:**
- App Service gets virtual network interface
- All outbound traffic routes through VNet
- Can reach private endpoints in the VNet

**Route All Setting:**
- **On**: ALL outbound traffic goes through VNet (recommended)
- **Off**: Only VNet address space goes through VNet

**Example Flow:**
```
App Service (myapp-web-5233)
    ↓ VNet Integration enabled
    ↓ Subnet: subnet-app-integration
    ↓ Route All: ON
    → Can access: 10.0.2.5 (SQL private endpoint)
    → Can access: myapp-sql-3216.database.windows.net resolves to 10.0.2.5
```

---

### 5. Private DNS Zone for SQL

**What it is:** Private DNS server that resolves SQL Database names to private IPs

**How it works:**
- Default DNS: `myapp-sql-3216.database.windows.net` → public IP
- Private DNS: `myapp-sql-3216.database.windows.net` → private IP (10.0.2.x)

**DNS Zones by Service:**

| Service | Private DNS Zone |
|---------|-----------------|
| SQL Database | `privatelink.database.windows.net` |
| Key Vault | `privatelink.vaultcore.azure.net` |
| Storage Account | `privatelink.blob.core.windows.net` |
| Cosmos DB | `privatelink.documents.azure.com` |

**Why you need it:**
- Your application doesn't need code changes
- Connection string stays the same
- DNS automatically routes to private endpoint

**Example:**
```
Connection String: Server=myapp-sql-3216.database.windows.net;...
   ↓ (DNS lookup via Private DNS Zone)
   ↓ Returns: 10.0.2.5 (private IP)
   → Connects to private endpoint ✅
```

---

## Complete Workflow Example

### Step-by-Step Transformation

#### Current State (Public):
1. App Service has outbound IP: 172.179.96.34
2. SQL Server public IP: 20.40.50.60 (example)
3. Firewall allows 0.0.0.0 (Azure services)
4. Connection: App → Internet → SQL Public IP

#### After Phase 1 (VNet Created):
1. VNet created: 10.0.0.0/16
2. Subnet created: subnet-app-integration (10.0.1.0/24)
3. Subnet created: subnet-private-endpoints (10.0.2.0/24)
4. Connection: Still public (no change yet)

#### After Phase 2 (Private Endpoint):
1. Private Endpoint created: 10.0.2.5 (in subnet-private-endpoints)
2. DNS Zone created: privatelink.database.windows.net
3. DNS resolution updated: myapp-sql-3216.database.windows.net → 10.0.2.5
4. Connection: Still public (app not in VNet yet)

#### After Phase 3 (Public Access Restricted):
1. SQL Server: Public access disabled
2. Firewall rules: Cleared
3. Only private endpoint works
4. Connection: ❌ App can't connect (no VNet integration)

#### After Phase 4 (VNet Integration):
1. App Service connected to subnet-app-integration
2. Route All enabled
3. DNS resolves to private IP
4. Connection: ✅ App → VNet → Private Endpoint → SQL Database

### Security Posture Improvements

| Threat | Before | After |
|--------|--------|-------|
| **Port Scanning** | ⚠️ Exposed | ✅ Not visible |
| **Brute Force Attacks** | ⚠️ Can attempt | ✅ No access |
| **DDoS Attacks** | ⚠️ Vulnerable | ✅ Protected |
| **Data Exfiltration** | ⚠️ Internet path | ✅ Private path |
| **Man-in-the-Middle** | ⚠️ Public network | ✅ Azure backbone |
| **IP Spoofing** | ⚠️ Possible | ✅ VNet isolation |

---

## Phase 1: Create Virtual Network

> ⚠️ **Note**: If you already created a VNet for Key Vault Private Link, skip to Phase 2.

### Step 1: Navigate to Virtual Networks
1. Open **Azure Portal** (portal.azure.com)
2. Search for **"Virtual networks"** in top search bar
3. Click **"+ Create"**

### Step 2: Create VNet - Basics Tab
- **Subscription**: (your subscription)
- **Resource group**: `rg-test-ntt`
- **Virtual network name**: `vnet-test-ntt`
- **Region**: `West US` ⚠️ **Must match SQL Server region**
- Click **"Next: IP Addresses"**

### Step 3: Create VNet - IP Addresses Tab

**Configure Address Space:**
- **IPv4 address space**: `10.0.0.0/16`

**Create 2 Subnets** - Click **"+ Add subnet"** for each:

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

> ℹ️ **Why**: This subnet hosts the private endpoint for SQL Database.

> 💡 **What does "Private endpoint network policy: Disabled" mean?**  
> This means NSGs and Route Tables do NOT apply to private endpoint traffic - it flows freely within the VNet. This is the simplest and recommended configuration.

**Finish Creation:**
- Click **"Review + create"**
- Click **"Create"**
- ⏱️ Wait for deployment (~1-2 minutes)

---

## Phase 2: Create Private Endpoint for SQL Database

### Step 4: Navigate to SQL Server
1. Azure Portal → Search **"myapp-sql-3216"**
2. Click on your SQL Server

### Step 5: Access Private Endpoint Settings
In the **left menu**:
- Scroll to **"Security"** section
- Click **"Networking"**

You'll see two tabs:
- **Public access**
- **Private access**

### Step 6: Create Private Endpoint

1. Click **"Private access"** tab
2. Click **"+ Create a private endpoint"**

#### Page 1 - Basics
- **Subscription**: (your subscription)
- **Resource group**: `rg-test-ntt`
- **Name**: `pe-myapp-sql-3216`
- **Network Interface Name**: `nic-pe-myapp-sql-3216` (auto-filled)
- **Region**: `West US` ⚠️ **Must match SQL Server region**
- Click **"Next: Resource"**

#### Page 2 - Resource
- **Connection method**: `Connect to an Azure resource in my directory` ✅
- **Subscription**: (your subscription)
- **Resource type**: `Microsoft.Sql/servers`
- **Resource**: `myapp-sql-3216` (select from dropdown)
- **Target sub-resource**: `sqlServer` (only option)
- Click **"Next: Virtual Network"**

> ℹ️ **Note**: Target sub-resource "sqlServer" creates a single private endpoint for the entire SQL Server (all databases)

#### Page 3 - Virtual Network
- **Virtual network**: `vnet-test-ntt`
- **Subnet**: `subnet-private-endpoints (10.0.2.0/24)`
- **Private IP configuration**: `Dynamically allocate IP address` ✅
- **Application security group**: None

**Integrate with private DNS zone:** ⚠️ **Critical**
- **Integrate with private DNS zone**: `Yes` (toggle ON)
- **Subscription**: (your subscription)
- **Resource group**: `rg-test-ntt`
- **Private DNS Zone**: Auto-creates `privatelink.database.windows.net`

> ℹ️ **Why DNS integration is critical:**  
> Without this, your connection string `myapp-sql-3216.database.windows.net` will still resolve to the public IP. The Private DNS Zone automatically updates DNS to return the private IP (10.0.2.x) instead.

**Finish:**
- Click **"Next: Tags"** (optional)
- Click **"Next: Review + create"**
- Click **"Create"**
- ⏱️ Wait for deployment (~3-5 minutes)

### Step 7: Verify Private Endpoint

Once deployed:
1. Go back to SQL Server → **Networking** → **Private access** tab
2. You should see: `pe-myapp-sql-3216` with status **"Approved"**
3. Note the **Private IP address** (e.g., 10.0.2.4)

**Test DNS Resolution** (optional):
```powershell
# From a VM in the same VNet, run:
nslookup myapp-sql-3216.database.windows.net
# Should return: 10.0.2.x (private IP)
```

---

## Phase 3: Configure SQL Server Network Access

### Step 8: Update SQL Server Public Access Settings

1. Stay in SQL Server → **Networking**
2. Click **"Public access"** tab

Current settings will show:
- **Public network access**: Enabled
- **Firewall rules**: AllowAzureServices, AllowMyIP, etc.

### Step 9: Choose Your Security Model

**Choose Your Security Model:**

#### Option A - Maximum Security (Private Link Only) 🔒

**Use when**: Production environment, forcing all traffic through Private Link

- **Public network access**: Select **"Disable"**

✅ **Result**: 
- Only VNet-connected resources can access (via Private Endpoint)
- No public access at all
- Maximum security posture
- ⚠️ You'll lose Azure Portal query editor access (must use VNet-connected VM or Azure Bastion)

**Firewall Rules:** All cleared automatically

**Apply Settings:**
- Click **"Save"** at the top
- ⏱️ Wait ~30 seconds for changes to propagate

---

#### Option B - Hybrid Access (Recommended for Testing) 🔐

**Use when**: Testing setup, need Azure Portal access, troubleshooting

- **Public network access**: Select **"Selected networks"**

**Firewall Configuration:**

**Add your IP address:**
1. Under **"Firewall rules"** section
2. Click **"+ Add your client IPv4 address"** 
3. Rule name will be auto-generated (e.g., "ClientIPAddress_2026-05-08")

**Keep or remove Azure services:**
- You can remove the `0.0.0.0 - 0.0.0.0` rule (AllowAzureServices)
- Not needed anymore since your app uses private endpoint

**Example configuration:**
```
Firewall rules:
├─ ClientIPAddress_2026-05-08: 50.106.54.222 (your IP)
└─ (AllowAzureServices removed)
```

> 💡 **Note**: Even with your IP allowlisted, the app will prefer the Private Endpoint route (faster and more secure).

**Apply Settings:**
- Click **"Save"** at the top
- ⏱️ Wait ~30 seconds for changes to propagate

---

#### Understanding the Options

| Option | Private Endpoint Access | Public Portal Access | Other Azure Services | Security Level |
|--------|------------------------|---------------------|---------------------|----------------|
| **Option A** | ✅ Yes (via VNet) | ❌ No | ❌ No | Excellent |
| **Option B** | ✅ Yes (preferred) | ✅ Yes (your IP) | ❌ No | Good |

**Recommendation**: Start with **Option B** for testing, switch to **Option A** for production.

---

## Phase 4: Enable VNet Integration for Web App

### Step 10: Navigate to Web App
1. Azure Portal → Search **"myapp-web-5233"**
2. Click on your Web App

### Step 11: Access Networking Settings
In the **left menu**:
- Scroll to **"Settings"** section
- Click **"Networking"**

### Step 12: Configure VNet Integration

1. Under **"Outbound traffic configuration"** section
2. Click **"VNet integration"**
3. Click **"+ Add VNet"** (or **"Configure"** if already configured)

**VNet Integration Settings:**
- **Virtual Network**: `vnet-test-ntt`
- **Subnet**: `subnet-app-integration (10.0.1.0/24)`

> ⚠️ **Important**: Use the delegated subnet (subnet-app-integration), NOT the private endpoints subnet!

**Additional Settings:**
- **Route All**: ✅ **Enable** (toggle ON)

> ℹ️ **What is Route All?**  
> When enabled, ALL outbound traffic from your app routes through the VNet, including internet traffic. This ensures DNS queries use the Private DNS Zone.

**Apply:**
- Click **"OK"** or **"Connect"**
- ⏱️ Wait ~1-2 minutes for configuration

### Step 13: Restart Web App

**Important**: Restart required for VNet integration to take effect!

1. At the top of the Web App page, click **"Restart"**
2. Click **"Yes"** to confirm
3. ⏱️ Wait ~30 seconds

---

## Phase 5: Verify Private Link Connection

### Step 14: Test Application

1. Open your web app: **https://myapp-web-5233.azurewebsites.net/**
2. Navigate to **"Dashboard"** page
3. Verify data loads successfully

✅ **Success**: Data loads → App is using Private Endpoint

❌ **Failure**: 500 error or timeout → Check troubleshooting section

### Step 15: Verify DNS Resolution

Check that your app resolves SQL Server to private IP:

1. Go to Web App → **Development Tools** → **Console** (or **SSH**)
2. Run:
   ```bash
   nslookup myapp-sql-3216.database.windows.net
   ```

**Expected output:**
```
Server: 168.63.129.16
Address: 168.63.129.16

Non-authoritative answer:
Name: myapp-sql-3216.database.windows.net
Address: 10.0.2.4  ← Private IP (10.0.x.x)
```

❌ **If you see public IP (e.g., 20.x.x.x)**: Private DNS Zone not working correctly

### Step 16: Test from Outside VNet (Optional)

To verify public access is blocked:

1. From your **local machine** (not in VNet), try:
   ```bash
   nslookup myapp-sql-3216.database.windows.net
   ```

**Expected output:**
```
Address: 20.40.50.60  ← Public IP
```

2. Try to connect with SQL client (e.g., Azure Data Studio):
   - Server: `myapp-sql-3216.database.windows.net`
   - Authentication: Azure Active Directory

**Option A (Disabled public access):**
- ❌ Connection fails: "Public network access is disabled"
- ✅ Correct! Only VNet access works

**Option B (Selected networks with your IP):**
- ✅ Connection succeeds from your IP
- ❌ Connection fails from other IPs
- ✅ Correct! Only allowlisted IPs work

---

## Troubleshooting

### Issue 1: App Can't Connect to Database

**Symptoms:**
- 500 error on Dashboard page
- Error: "Cannot open server...requested by the login"

**Check:**
1. **VNet Integration**: Web App → Networking → VNet integration shows "Connected"
2. **Route All**: Enabled (toggle ON)
3. **Subnet**: Using `subnet-app-integration`, not `subnet-private-endpoints`
4. **Restart**: Web App restarted after VNet integration

**Solution:**
```powershell
# Verify VNet integration
az webapp vnet-integration list --name myapp-web-5233 --resource-group rg-test-ntt

# Should show: subnet-app-integration

# Restart app
az webapp restart --name myapp-web-5233 --resource-group rg-test-ntt
```

---

### Issue 2: DNS Resolves to Public IP

**Symptoms:**
- `nslookup` returns public IP (20.x.x.x) instead of private IP (10.0.x.x)

**Check:**
1. **Private DNS Zone**: Exists and named `privatelink.database.windows.net`
2. **VNet Link**: Private DNS Zone linked to `vnet-test-ntt`
3. **Route All**: Enabled on VNet integration

**Solution:**
1. Go to **Private DNS zones** → `privatelink.database.windows.net`
2. Click **"Virtual network links"**
3. Verify: `vnet-test-ntt` is linked with **"Auto-registration"** disabled
4. If missing, click **"+ Add"**:
   - Link name: `vnet-test-ntt-link`
   - Virtual network: `vnet-test-ntt`
   - Enable auto registration: ❌ No
   - Click **"OK"**

---

### Issue 3: Azure Portal Can't Query Database

**Symptoms:**
- Query editor in Azure Portal shows connection error
- Can't browse tables or run queries

**Cause:**
- Public access disabled (Option A)
- Your IP not allowlisted (Option B)

**Solution - Option 1 (Add your IP):**
1. SQL Server → Networking → Public access tab
2. Change to **"Selected networks"**
3. Click **"+ Add your client IPv4 address"**
4. Click **"Save"**

**Solution - Option 2 (Use VNet-connected VM):**
1. Deploy a VM in the same VNet
2. Install SQL tools (SSMS, Azure Data Studio)
3. Connect via private endpoint

---

### Issue 4: Private Endpoint Status "Pending"

**Symptoms:**
- Private endpoint shows status "Pending" instead of "Approved"

**Check:**
1. SQL Server → Networking → Private access
2. Check connection status

**Solution:**
1. Click on the private endpoint connection
2. Click **"Approve"**
3. Add approval message: "Approved for VNet access"
4. Click **"Yes"**
5. Wait ~1 minute for status to update

---

### Issue 5: Managed Identity Can't Access Database

**Symptoms:**
- Error: "Login failed for user..."
- App can reach database but authentication fails

**Check:**
1. **Managed Identity**: Enabled on Web App
2. **SQL User**: Created for managed identity
3. **Permissions**: Granted db_datareader, db_datawriter, db_ddladmin

**Solution:**

**Step 1: Verify Managed Identity**
```powershell
az webapp identity show --name myapp-web-5233 --resource-group rg-test-ntt
# Note the "principalId"
```

**Step 2: Run SQL script in Azure Portal Query Editor**

Navigate to: SQL Database (SampleDB) → **Query editor**

```sql
-- Replace with your web app name
CREATE USER [myapp-web-5233] FROM EXTERNAL PROVIDER;

ALTER ROLE db_datareader ADD MEMBER [myapp-web-5233];
ALTER ROLE db_datawriter ADD MEMBER [myapp-web-5233];
ALTER ROLE db_ddladmin ADD MEMBER [myapp-web-5233];

-- Verify
SELECT name, type_desc FROM sys.database_principals WHERE name = 'myapp-web-5233';
```

---

## Security Best Practices

### 1. Disable Public Access in Production

Once testing is complete:
- Set public network access to **"Disabled"**
- Remove all firewall rules
- Document any exceptions required

### 2. Use Network Security Groups (NSGs)

Add NSG to `subnet-private-endpoints`:
```
Inbound Rules:
├─ Allow: subnet-app-integration (10.0.1.0/24) → Port 1433
└─ Deny: All other traffic
```

### 3. Enable Azure AD-Only Authentication

SQL Server already has Azure AD-only authentication enabled:
```
administratorType: ActiveDirectory
azureAdOnlyAuthentication: true
```

**Benefit**: Eliminates SQL authentication attacks

### 4. Enable Audit Logging

1. SQL Server → **Auditing**
2. Enable auditing
3. Send logs to Log Analytics workspace

### 5. Use Private Endpoint for Multiple Databases

One private endpoint covers all databases on the SQL Server:
```
pe-myapp-sql-3216 → myapp-sql-3216
    ├─ SampleDB ✅
    ├─ ProductionDB ✅
    └─ AnalyticsDB ✅
```

### 6. Implement Least Privilege

Grant only required permissions:
- **Read-only apps**: db_datareader only
- **Web apps**: db_datareader + db_datawriter
- **Admin apps**: db_datareader + db_datawriter + db_ddladmin

---

## Cost Considerations

### Private Endpoint Pricing

**Private Endpoint Cost:**
- ~$7.50/month per private endpoint
- ~$0.01/GB data processed

**Private DNS Zone Cost:**
- $0.50/month per zone
- First 25 zones free (usually)

**Total for SQL Private Link:**
- ~$8/month (1 private endpoint + 1 DNS zone)

**Tip**: One private endpoint can serve multiple databases on same server!

---

## Testing Checklist

After completing setup, verify:

- [ ] Private endpoint created with status "Approved"
- [ ] Private IP assigned (e.g., 10.0.2.4)
- [ ] Private DNS Zone created: `privatelink.database.windows.net`
- [ ] VNet link exists: `vnet-test-ntt` → DNS Zone
- [ ] VNet Integration enabled on Web App
- [ ] Subnet: `subnet-app-integration`
- [ ] Route All: Enabled
- [ ] Web App restarted after VNet integration
- [ ] DNS resolves to private IP (10.0.x.x)
- [ ] Application loads data successfully
- [ ] Public access disabled (or restricted)
- [ ] Azure Portal access working (if needed)

---

## Rollback Plan

If you need to revert to public access:

### Step 1: Re-enable Public Access
```powershell
az sql server update \
  --name myapp-sql-3216 \
  --resource-group rg-test-ntt \
  --enable-public-network true
```

### Step 2: Add Firewall Rules
```powershell
# Allow Azure services
az sql server firewall-rule create \
  --server myapp-sql-3216 \
  --resource-group rg-test-ntt \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Step 3: Remove VNet Integration (Optional)
1. Web App → Networking → VNet integration
2. Click **"Disconnect"**
3. Restart Web App

### Step 4: Delete Private Endpoint (Optional)
1. SQL Server → Networking → Private access
2. Click on `pe-myapp-sql-3216`
3. Click **"Delete"**

---

## Next Steps

After enabling SQL Database Private Link:

1. ✅ **Enable Private Link for Key Vault** - Follow guide: `Enable-PrivateLink-AzurePortal-Guide.md`
2. ✅ **Document your architecture** - Update diagrams with private endpoints
3. ✅ **Test disaster recovery** - Ensure backups and restores work
4. ✅ **Monitor performance** - Check latency improvements
5. ✅ **Implement additional security** - NSGs, Azure Firewall, etc.

---

## Additional Resources

- [Azure Private Link Documentation](https://docs.microsoft.com/azure/private-link/)
- [SQL Database Private Endpoint](https://docs.microsoft.com/azure/azure-sql/database/private-endpoint-overview)
- [VNet Integration for App Service](https://docs.microsoft.com/azure/app-service/overview-vnet-integration)
- [Private DNS Zones](https://docs.microsoft.com/azure/dns/private-dns-overview)
- [SQL Database Security Best Practices](https://docs.microsoft.com/azure/azure-sql/database/security-best-practice)

---

## Summary

🎉 **Congratulations!** You've successfully enabled Private Link for Azure SQL Database!

**What you achieved:**
- ✅ SQL Database accessible only via private network
- ✅ Zero exposure to public internet
- ✅ Traffic never leaves Azure backbone
- ✅ Simplified network security
- ✅ Compliance-ready architecture
- ✅ Improved security posture

**Architecture:**
```
Internet ❌
   
VNet (10.0.0.0/16) ✅
   ├─ App Service (via VNet Integration)
   │     ↓
   ├─ Private Endpoint (10.0.2.4)
   │     ↓
   └─ SQL Database (myapp-sql-3216/SampleDB)
         [Public access: Disabled]
```

Your application is now significantly more secure! 🔒
