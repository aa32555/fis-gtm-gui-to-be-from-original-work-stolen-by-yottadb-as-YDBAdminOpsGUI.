<!--
#################################################################
#                                                               #
# Copyright (c) 2021-2022 YottaDB LLC and/or its subsidiaries.  #
# All rights reserved.                                          #
#                                                               #
#   This source code contains the intellectual property         #
#   of its copyright holder(s), and is made available           #
#   under a license.  If you do not know the terms of           #
#   the license, please stop and do not read further.           #
#                                                               #
#################################################################
-->
<template>
  <q-layout :class="$q.dark.isActive ? 'bg-banner-dark' : 'bg-banner-light'">
    <q-header
      v-if="(settingsEntered && isNotSPA) || !isNotSPA"
      elevated
      class="text-white"
      height-hint="61.59"
      :class="$q.dark.isActive ? 'bg-purple' : 'bg-orange'"
    >
      <q-toolbar class="q-py-sm q-px-md">
        <q-btn
          round
          dense
          flat
          :ripple="false"
          style="margin-right:10px"
          :to="'/'"
          id="main-navigation-page"
        >
          <q-avatar size="42px">
            <img src="~assets/logo.png" style="background-color:white;" />
          </q-avatar>
        </q-btn>

        <div
          v-if="$q.screen.gt.xs"
          class="GL__toolbar-link q-ml-xs q-gutter-md text-body2 text-weight-bold row items-center "
        >
          <q-btn-dropdown no-caps flat :label="$t('toolbar.system_management')" dense>
            <q-list>
              <q-item clickable v-close-popup :to="'/processes'" dense>
                {{ $t("toolbar.running_processes") }}
              </q-item>
              <q-item clickable v-close-popup :to="'/gde'" dense>
                {{ $t("toolbar.global_directory_editor") }}
              </q-item>
            </q-list>
          </q-btn-dropdown>
          <q-btn-dropdown no-caps flat :label="$t('toolbar.system_explorer')" dense>
            <q-list>
              <q-item clickable v-close-popup :to="'/routines'" dense>
               {{ $t("toolbar.routines") }}
              </q-item>
              <q-item clickable v-close-popup :to="'/globals'" dense>
              {{ $t("toolbar.globals") }}
              </q-item>
              <q-item clickable v-close-popup :to="'/octo-sql'" dense>
                {{ $t("toolbar.sqltables") }}
              </q-item>
            </q-list>
          </q-btn-dropdown>
          <q-btn-dropdown  no-caps flat :label="$t('toolbar.utilities')" dense>
            <q-list> </q-list>
          </q-btn-dropdown>
          <q-btn-dropdown flat :label="$t('toolbar.documentation')" dense>
            <q-list>
              <q-item
                clickable
                :to="'/documentation/administration_and_operations'"
                dense
              >
                <span style="font-size:16px">
                  Administration and Operations
                </span>
              </q-item>
              <q-item
                clickable
                :to="'/documentation/multi-language_programmers_guide'"
                dense
              >
                <span style="font-size:16px">
                  Multi-Language Programmers Guide
                </span>
              </q-item>
              <q-item
                clickable
                :to="'/documentation/m_programmers_guide'"
                dense
              >
                <span style="font-size:16px">
                  M Programmers Guide
                </span>
              </q-item>
              <q-item
                clickable
                :to="'/documentation/messages_and_recovery_procedures'"
                dense
              >
                <span style="font-size:16px">
                  Messages and Recovery Procedures
                </span>
              </q-item>
              <q-item
                clickable
                :to="'/documentation/acculturation_guide'"
                dense
              >
                <span style="font-size:16px">
                  Acculturation Guide
                </span>
              </q-item>
              <q-item clickable :to="'/documentation/octo_documentation'" dense>
                <span style="font-size:16px">
                  Octo Documentation
                </span>
              </q-item>
              <q-item clickable :to="'/documentation/plugins'" dense>
                <span style="font-size:16px">
                  Plugins
                </span>
              </q-item>
            </q-list>
          </q-btn-dropdown>
        </div>

        <q-space />
        <div class=" row items-center no-wrap">


  <q-btn-dropdown
      v-if="isNotSPA"
      :class="$q.dark.isActive ? 'bg-purple' : 'bg-orange'"
      style="font-size:18px;"
      flat
      no-caps
      icon="computer"
      :label="`${name}@${protocol}://${ip}:${port}`"
    >
      <q-list>
        <div class="q-pa-md">Saved connections</div>
        <q-item clickable v-close-popup @click="onConnectionClick(connections[connection])" v-for="(connection,index) in Object.keys(connections)" :key="'connection-'+index" dense>
          <q-item-section avatar>
            <q-avatar icon="computer" />
          </q-item-section>
          <q-item-section>
            <q-item-label>{{connections[connection].name}}</q-item-label>
            <q-item-label caption>{{`${connections[connection].protocol}://${connections[connection].ip}:${connections[connection].port}`}}</q-item-label>
          </q-item-section>
        </q-item>
      </q-list>
              <q-btn
            no-caps
            flat
            class="full-width"
            :label="'Clear saved connections'"
            :disable="checkingConnection"
            @click="$q.localStorage.set('ydb-app-connections', {});$q.notify('Cleared');"
          />
    </q-btn-dropdown>
          <q-select
            v-show="false"
            v-model="lang"
            :options="langOptions"
            dense
            borderless
            emit-value
            map-options
            options-dense
            label-color="white"
            style="width: 40px"
          >
            <template v-slot:selected-item="scope">
              <span class="text-white"> {{ scope.opt.label }} </span>
            </template>
          </q-select>
          <q-btn
            v-if="isNotSPA"
            dense
            flat
            round
            size="md"
            :icon="'settings_ethernet'"
            @click="settingsDialog = true"
          />
          <q-btn
            dense
            flat
            round
            size="md"
            :icon="theme === 'light' ? 'wb_sunny' : 'nightlight_round'"
            @click="changeTheme"
          />
        </div>
      </q-toolbar>
    </q-header>
    <q-dialog v-model="settingsDialog" persistent>
      <q-card style="min-width: 350px">
        <img
          v-if="!$q.dark.isActive"
          alt="Quasar logo"
          src="~assets/YottaDB_logo-light.svg"
          style="max-width:50vw;padding:10px"
        />
        <img
          v-if="$q.dark.isActive"
          alt="Quasar logo"
          src="~assets/YottaDB_logo-dark.svg"
          style="max-width:50vw;padding:10px"
        />
        <q-card-section>
          <div class="text-h6">Connection Info</div>
          <div></div>
        </q-card-section>

        <q-card-section class="q-pt-none">
          <q-input
            v-model="ip"
            outlined
            label="IP*"
            :dense="true"
            hint="Server IP. e.g. 192.168.1.5"
            :rules="[
              val => ValidateIPaddress(val) || 'Please type a valid IP!'
            ]"
          />
        </q-card-section>
        <q-card-section class="q-pt-none">
          <q-input
            v-model="port"
            outlined
            label="Port*"
            :dense="true"
            hint="Server port. e.g. 8089"
            :rules="[
              val =>
                (parseInt(val) > 0 && parseInt(val) < 999999) ||
                'Please type a valid Port!'
            ]"
          />
        </q-card-section>
        <q-card-section class="q-pt-none">
          <q-select
            outlined
            :options="['http', 'https']"
            label="Protocol*"
            v-model="protocol"
            :dense="true"
            :hint="'Connection protocol'"
          />
        </q-card-section>
      <q-card-section class="q-pt-none">
            <q-input
            v-model="name"
            outlined
            label="Connection name*"
            :dense="true"
            hint="YottaDB instance 7"
            :rules="[
              val =>
                (val && val.length) ||
                'Please type a valid conncection name!'
            ]"
          />
        </q-card-section>

        <q-card-actions align="right" class="text-primary">
          <q-btn
            no-caps
            flat
            :disable="checkingConnection"
            :label="checkingConnection ? 'Checking connection...' : 'Connect'"
            @click="setSettings"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
    <q-page-container v-if="(settingsEntered && isNotSPA) || !isNotSPA">
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
export default {
  name: "MyLayout",
  data() {
    return {
      connections:{},
      name:'',
      checkingConnection: false,
      settingsDialog: false,
      ip: "",
      protocol: "http",
      port: "",
      theme: "light",
      // lang: this.$i18n.locale,
      lang: "en-us",
      langOptions: [
        { value: "en-us", label: "EN" },
        { value: "ar", label: "AR" }
      ],
      settingsEntered: false
    };
  },
  mounted() {
    if (this.$i18n.locale !== "en-us") {
      this.lang = "en-us";
    }
  },
  created() {
    this.connections =  this.$q.localStorage.getItem("ydb-app-connections") || {}; 
    this.theme = this.$q.localStorage.getItem("ydb-app-theme") || "light";
    if (this.theme === "dark") {
      this.$q.dark.set(true);
    } else {
      this.$q.dark.set(false);
    }
    if (
      this.$q.localStorage.getItem("ydb-app-ip") &&
      this.$q.localStorage.getItem("ydb-app-port") &&
      this.$q.localStorage.getItem("ydb-app-protocol") && 
      this.$q.localStorage.getItem("ydb-app-name")
    ) {
      this.ip = this.$q.localStorage.getItem("ydb-app-ip");
      this.port = this.$q.localStorage.getItem("ydb-app-port");
      this.protocol = this.$q.localStorage.getItem("ydb-app-protocol");
      this.name = this.$q.localStorage.getItem("ydb-app-name");
      let details = {
        ip: this.ip,
        port: this.port,
        protocol: this.protocol,
        name: this.name
      };
      this.$store.dispatch("app/setAppDetails", details);
      this.settingsEntered = true;
    } else if (this.isNotSPA) {
      setTimeout(() => {
        this.settingsDialog = true;
      }, 1000);
    }
  },
  methods: {
    async onConnectionClick(details){
      if (details.port && details.ip && details.protocol && details.name) {
        this.port = details.port
        this.ip = details.ip
        this.protocol = details.protocol
        this.name = details.name
        await this.setSettings()
      }
    },
    async setSettings() {
      if (this.port && this.ip && this.protocol && this.name) {
        let details = {
          ip: this.ip,
          port: this.port,
          protocol: this.protocol,
          name: this.name
        };
        this.$q.localStorage.set("ydb-app-ip", this.ip);
        this.$q.localStorage.set("ydb-app-port", this.port);
        this.$q.localStorage.set("ydb-app-protocol", this.protocol);
        this.$q.localStorage.set("ydb-app-name", this.name);
        this.$store.dispatch("app/setAppDetails", details);
        this.checkingConnection = true;
        let data = await this.$M("PING^%YDBWEBAPI");
        if (!data || !data.RESULT || data.RESULT !== "PONG") {
          this.checkingConnection = false;
          this.$q.notify({
            message: "Connection failed!",
            color: "negative"
          });
          let details = {
            ip: "",
            port: "",
            protocol: "",
            name:""
          };
          this.$q.localStorage.set("ydb-app-ip", "");
          this.$q.localStorage.set("ydb-app-port", "");
          this.$q.localStorage.set("ydb-app-protocol", "");
          this.$q.localStorage.set("ydb-app-name", "");
          this.$store.dispatch("app/setAppDetails", details);
          location.reload(true);
          return;
        } else {
          let connections = this.$q.localStorage.getItem("ydb-app-connections") || {};
          let key = details.name+'-'+details.protocol+'-'+details.ip+'-'+details.port
          connections[key]=details
          this.connections = connections
          this.$q.localStorage.set("ydb-app-connections", connections);
          this.checkingConnection = false;
          this.$q.notify({
            message: "Connection succeeded!",
            color: "positive"
          });
        }
      } else {
        this.$q.notify({
          message:
            "Please enter the IP, Port and Protocol to connect to the server",
          color: "negative"
        });
        return;
        /*
        this.port = '',
        this.protocol = '',
        this.ip = ''
        this.$q.localStorage.set('ydb-app-ip', '')
        this.$q.localStorage.set('ydb-app-port', '')
        this.$q.localStorage.set('ydb-app-protocol', '')
      */
      }
      this.settingsDialog = false;
      location.reload(true);
    },
    ValidateIPaddress(ipaddress) {
      if (ipaddress === "localhost") {
        return true;
      } else if (
        /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(
          ipaddress
        )
      ) {
        return true;
      } else {
        return false;
      }
    },
    changeTheme() {
      if (this.theme === "light") {
        this.$q.dark.set(true);
        this.theme = "dark";
      } else {
        this.$q.dark.set(false);
        this.theme = "light";
      }
      this.$q.localStorage.set("ydb-app-theme", this.theme);
    }
  },
  watch: {
    lang(lang) {
      this.$i18n.locale = lang;
    }
  },
  computed: {
    isNotSPA() {
      return process.env.MODE !== "spa";
    }
  }
};
</script>

<style lang="sass">
.GL
  &__select-GL__menu-link
    .default-type
      visibility: hidden
    &:hover
      background: #0366d6
      color: white
      .q-item__section--side
        color: white
      .default-type
        visibility: visible
  &__toolbar-link
    a
      color: white
      text-decoration: none
      &:hover
        opacity: 0.7
  &__menu-link:hover
    background: #0366d6
    color: white
  &__menu-link-signed-in,
  &__menu-link-status
    &:hover
      & > div
        background: white !important
  &__menu-link-status
    color: $blue-grey-6
    &:hover
      color: $light-blue-9
  &__toolbar-select.q-field--focused
    width: 450px !important
    .q-field__append
      display: none
</style>
<style scoped>
.rotating {
  transition: transform 1s ease-in-out;
}
.rotating:hover {
  transform: rotateZ(360deg);
}
.bg-banner-light {
  background-image: url(banner-image-light.png);
  background-size: cover;
}
.bg-banner-dark {
  background-image: url(banner-image-dark.jpg);
  background-size: cover;
}
</style>
