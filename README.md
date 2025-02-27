# Microsoft First Party App Names & Graph Permissions

## 💡 Overview

Looking up the names of Microsoft first party applications and Graph Permissions can be quite tricky.

Microsoft publishes a static list of the common app names in the [Verify first-party Microsoft applications in sign-in reports](https://learn.microsoft.com/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in) doc.

There are a few problems with this.

* It is in markdown and is not easily consumable by scripts and KQL queries that need to perform lookups.
* It does not list all of the Microsoft apps that can be found through Microsoft Graph API.

With Graph Permissions you need to authentication with Microsoft Graph to get the list of application and delegate permissions. This is not always possible in a script or a KQL query.

## 🖥️ The solution

This repository provides an up-to-date list of Microsoft first party apps and Graph Permissions that can be easily consumed by scripts.

Use the following urls to consume this data in your scripts.

* **First Party Apps**
  * :diamond_shape_with_a_dot_inside: JSON → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.json](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.json)
  * :clipboard:  CSV → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.csv](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.csv)
* **Graph Permissions - App permissions**
  * :diamond_shape_with_a_dot_inside: JSON → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphAppRoles.json](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphAppRoles.json)
  * :clipboard:  CSV → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphAppRoles.csv](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphAppRoles.csv)
* **Graph Permissions - Delegate permissions**
  * :diamond_shape_with_a_dot_inside: JSON → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphDelegateRoles.json](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphDelegateRoles.json)
  * :clipboard:  CSV → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphDelegateRoles.csv](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/GraphDelegateRoles.csv)

## 📘 Data source

This repository runs a daily automation to generate the latest list of Microsoft first party application. The source of the data includes

* **Microsoft Graph** → `$filter = appOwnerOrganizationId eq [MicrosoftTenant]`
  * Run a query against a demo Microsoft 365 tenant and get a list of all the apps that belong to Microsoft.
* **Microsoft Entra Docs** → [Known Guids](https://github.com/MicrosoftDocs/entra-docs/blob/main/.docutune/dictionaries/known-guids.json)
  * Get the list GUIDs from the known guids file in the Microsoft Entra docs repo.
* **Microsoft Learn** → [Verify first-party Microsoft applications in sign-in reports](https://learn.microsoft.com/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in)
  * Parse the markdown from the tables in [this Microsoft Learn doc](https://learn.microsoft.com/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in)
* **Community contributed app names** → [./customdata/OtherMicrosoftApps.csv](/customdata/OtherMicrosoftApps.csv)
  *  App names contributed by the community to this repository. Submit a PR to add entries to this file.

If an app id exists in more than one list the order of precedence for the app name is → Graph, Learn and then GitHub

![Image with a funnel illustrating the three data sources and the two output files.](/assets/overview.png)

## ⋔ Forking this repo

Follow the steps below if you need to set up this automation in your own repo.
* Fork this repo
* Create an app in your tenant with the Application.Read.All app permission following the instructions on this page to configure [Workload ID federation](https://github.com/marketplace/actions/azure-ad-workload-identity-federation)

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->


