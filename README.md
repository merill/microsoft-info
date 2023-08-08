# Microsoft First Party App Info

## 💡 Overview

Looking up the names of Microsoft first party applications can be quite tricky. Microsoft publishes a static list of the common app names in the [Verify first-party Microsoft applications in sign-in reports](https://learn.microsoft.com/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in) doc.

There are a few problems with this.

* It is in markdown and is not easily consumable by scripts and KQL queries that need to perform lookups.
* It does not list all of the Microsoft apps that can be found through Microsoft Graph API.

## 🎉 The Solution

This repository provides an up-to-date list of Microsoft first party apps that can be easily consumed by scripts.

Use the following urls to consume this data in your scripts.

* :diamond_shape_with_a_dot_inside: JSON → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.json](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.json)
* :clipboard:  CSV → [https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.csv](https://raw.githubusercontent.com/merill/microsoft-info/main/_info/MicrosoftApps.csv)


## Data sources

This repository runs a daily automation to generate the latest list of Microsoft first party application. The source of the data includes

* **Microsoft Graph** → `$filter = appOwnerOrganizationId eq [MicrosoftTenant]`
  * Run a query against a demo Microsoft 365 tenant and get a list of all the apps that belong to Microsoft.
* **Microsoft Learn** → [Verify first-party Microsoft applications in sign-in reports](https://learn.microsoft.com/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in)
  * Parse the markdown from the tables in [this Microsoft Learn doc](https://learn.microsoft.com/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in)
* **Community contributed app names** → [./customdata/OtherMicrosoftApps.csv]([/customdata/OtherMicrosoftApps.csv])
  *  App names contributed by the community to this repository. Submit a PR to add entries to this file.

If an app id exists in more than one list the order of precedence for the app name is → Graph, Learn and then GitHub

## Forking this repo

Follow the steps below if you need to set up this automation in your own repo.
* Fork this repo
* Create an app in your tenant with the Application.Read.All app permission following the instructions on this page to configure [Workload ID federation](https://github.com/marketplace/actions/azure-ad-workload-identity-federation)



