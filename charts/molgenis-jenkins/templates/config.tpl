{{- define "override_config_map" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "jenkins.fullname" . }}
data:
  config.xml: |-
    <?xml version='1.0' encoding='UTF-8'?>
    <hudson>
      <disabledAdministrativeMonitors/>
      <version>{{ .Values.Master.ImageTag }}</version>
      <numExecutors>0</numExecutors>
      <mode>NORMAL</mode>
      <useSecurity>{{ .Values.Master.UseSecurity }}</useSecurity>
      <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
        <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
      </authorizationStrategy>
{{- if .Values.Master.Security.UseGitHub }}
      <securityRealm class="org.jenkinsci.plugins.GithubSecurityRealm">
        <githubWebUri>https://github.com</githubWebUri>
        <githubApiUri>https://api.github.com</githubApiUri>
        <clientID>{{ .Values.Master.Security.GitHub.ClientID }}</clientID>
        <clientSecret>{{ .Values.Master.Security.GitHub.ClientSecret }}</clientSecret>
        <oauthScopes>read:org,user:email</oauthScopes>
      </securityRealm>
{{- else }}
      <securityRealm class="hudson.security.LegacySecurityRealm"/>
{{- end }}
      <disableRememberMe>false</disableRememberMe>
      <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
      <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
      <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
      <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
      <jdks/>
      <primaryView>dev</primaryView>
      <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
      <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
      <clouds>
        <org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud plugin="kubernetes@{{ template "jenkins.kubernetes-version" . }}">
          <name>kubernetes</name>
          <templates>
{{- range $podName, $pod := .Values.Pods }}
            <org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
              <inheritFrom>{{ $pod.InheritFrom | default "" }}</inheritFrom>
              <name>{{ $podName }}</name>
              <instanceCap>2147483647</instanceCap>
              <idleMinutes>0</idleMinutes>
              <label>{{ .Label }}</label>
              <nodeSelector>
                {{- $local := dict "first" true }}
                {{- range $key, $value := .NodeSelector }}
                  {{- if not $local.first }},{{- end }}
                  {{- $key }}={{ $value }}
                  {{- $_ := set $local "first" false }}
                {{- end }}</nodeSelector>
                <nodeUsageMode>{{ .NodeUsageMode }}</nodeUsageMode>
              <volumes>
{{- range $index, $volume := .volumes }}
                <org.csanchez.jenkins.plugins.kubernetes.volumes.{{ .type }}Volume>
{{- range $key, $value := $volume }}{{- if not (eq $key "type") }}
                  <{{ $key }}>{{ $value }}</{{ $key }}>
{{- end }}{{- end }}
                </org.csanchez.jenkins.plugins.kubernetes.volumes.{{ .type }}Volume>
{{- end }}
              </volumes>
              <containers>
{{- range $containerName, $container := .Containers }}
                <org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
                  <name>{{ $containerName }}</name>
                  <image>{{ .Image }}:{{ .ImageTag | default "latest" }}</image>
                  <ports>
{{- range $index, $envVar := .Ports }}
                    <org.csanchez.jenkins.plugins.kubernetes.PortMapping>
                      <name>{{ .name }}</name>
                      <containerPort>{{ .containerPort }}</containerPort>
                      <hostPort>{{ .hostPort }}</hostPort>
                    </org.csanchez.jenkins.plugins.kubernetes.PortMapping>
{{- end }}
                  </ports>
{{- if .Privileged }}
                  <privileged>true</privileged>
{{- else }}
                  <privileged>false</privileged>
{{- end }}
{{- if .AlwaysPullImage }}
                  <alwaysPullImage>true</alwaysPullImage>
{{- else }}
                  <alwaysPullImage>false</alwaysPullImage>
{{- end }}
                  <workingDir>{{ .WorkingDir | default "" }}</workingDir>
                  <command>{{ .Command | default "" }}</command>
                  <args>{{ .Args | default "" }}</args>
{{- if .TTY }}
                  <ttyEnabled>true</ttyEnabled>
{{- else }}
                  <ttyEnabled>false</ttyEnabled>
{{- end }}
                  <envVars>
{{- range $index, $envVar := .EnvVars }}
                    <org.csanchez.jenkins.plugins.kubernetes.model.{{ .type }}EnvVar>
{{- range $key, $value := $envVar }}{{- if not (eq $key "type") }}
                      <{{ $key }}>{{ $value }}</{{ $key }}>
{{- end }}{{- end }}
                    </org.csanchez.jenkins.plugins.kubernetes.model.{{ .type }}EnvVar>
{{- end }}
                  </envVars>
{{- if .resources }}
{{- if .resources.requests }}
                  <resourceRequestCpu>{{ .resources.requests.cpu | default "" }}</resourceRequestCpu>
                  <resourceRequestMemory>{{ .resources.requests.memory | default "" }}</resourceRequestMemory>
{{- end }}
{{- if .resources.limits }}
                  <resourceLimitCpu>{{ .resources.limits.cpu | default "" }}</resourceLimitCpu>
                  <resourceLimitMemory>{{ .resources.limits.memory | default "" }}</resourceLimitMemory>
{{- end }}
{{- end }}
                  <podRetention class="org.csanchez.jenkins.plugins.kubernetes.pod.retention.{{ .Retention | default "Default" }}"/>
                </org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
{{- end }}
              </containers>
              <envVars>
                  <org.csanchez.jenkins.plugins.kubernetes.model.KeyValueEnvVar>
                    <key>JENKINS_URL</key>
                    <value>http://{{ template "jenkins.fullname" $ }}:{{$.Values.Master.ServicePort}}{{ default "" $.Values.Master.JenkinsUriPrefix }}</value>
                  </org.csanchez.jenkins.plugins.kubernetes.model.KeyValueEnvVar>
{{- range $index, $envVar := .EnvVars }}
                <org.csanchez.jenkins.plugins.kubernetes.model.{{ .type }}EnvVar>
{{- range $key, $value := $envVar }}{{- if not (eq $key "type") }}
                  <{{ $key }}>{{ $value }}</{{ $key }}>
{{- end }}{{- end }}
                </org.csanchez.jenkins.plugins.kubernetes.model.{{ .type }}EnvVar>
{{- end }}
              </envVars>
              <annotations/>
{{- if .ImagePullSecret }}
              <imagePullSecrets>
                <org.csanchez.jenkins.plugins.kubernetes.PodImagePullSecret>
                  <name>{{ .ImagePullSecret }}</name>
                </org.csanchez.jenkins.plugins.kubernetes.PodImagePullSecret>
              </imagePullSecrets>
{{- else }}
              <imagePullSecrets/>
{{- end }}
              <nodeProperties/>
            </org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
{{- end }}
          </templates>
          <serverUrl>https://kubernetes.default</serverUrl>
          <skipTlsVerify>false</skipTlsVerify>
          <namespace>{{ .Release.Namespace }}</namespace>
          <jenkinsUrl>http://{{ template "jenkins.fullname" . }}:{{.Values.Master.ServicePort}}{{ default "" .Values.Master.JenkinsUriPrefix }}</jenkinsUrl>
          <jenkinsTunnel>{{ template "jenkins.fullname" . }}-agent:50000</jenkinsTunnel>
          <containerCap>50</containerCap>
          <retentionTimeout>5</retentionTimeout>
          <connectTimeout>0</connectTimeout>
          <readTimeout>0</readTimeout>
        </org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud>
      </clouds>
      <quietPeriod>5</quietPeriod>
      <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
      <views>
        <hudson.model.AllView>
          <owner class="hudson" reference="../../.."/>
          <name>all</name>
          <filterExecutors>false</filterExecutors>
          <filterQueue>false</filterQueue>
          <properties class="hudson.model.View$PropertyList"/>
        </hudson.model.AllView>
{{- range $viewName, $view := .Values.Master.Views }}
        <listView>
          <owner class="hudson" reference="../../.."/>
          <name>{{ $viewName }}</name>
          <filterExecutors>false</filterExecutors>
          <filterQueue>false</filterQueue>
          <properties class="hudson.model.View$PropertyList"/>
          <jobNames>
             <comparator class="hudson.util.CaseInsensitiveComparator" reference="../../../listView/jobNames/comparator"/>
{{- range $index, $job := $view }}
             <string>{{ $job }}</string>
{{- end }}
          </jobNames>
          <jobFilters/>
          <columns>
            <hudson.views.StatusColumn/>
            <hudson.views.WeatherColumn/>
            <hudson.views.JobColumn/>
            <hudson.views.LastSuccessColumn/>
            <hudson.views.LastFailureColumn/>
            <hudson.views.LastDurationColumn/>
            <hudson.views.BuildButtonColumn/>
            <hudson.plugins.favorite.column.FavoriteColumn plugin="favorite@2.3.2"/>
          </columns>
          <recurse>false</recurse>
        </listView>
{{- end }}
      </views>
      <primaryView>{{ .Values.Master.DefaultView }}</primaryView>
      <slaveAgentPort>50000</slaveAgentPort>
      <disabledAgentProtocols>
{{- range .Values.Master.DisabledAgentProtocols }}
        <string>{{ . }}</string>
{{- end }}
      </disabledAgentProtocols>
      <label></label>
{{- if .Values.Master.CSRF.DefaultCrumbIssuer.Enabled }}
      <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
{{- if .Values.Master.CSRF.DefaultCrumbIssuer.ProxyCompatability }}
        <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
{{- end }}
      </crumbIssuer>
{{- end }}
      <nodeProperties/>
      <globalNodeProperties/>
      <noUsageStatistics>true</noUsageStatistics>
    </hudson>
{{- if .Values.Master.ScriptApproval }}
  scriptapproval.xml: |-
    <?xml version='1.0' encoding='UTF-8'?>
    <scriptApproval plugin="script-security@1.27">
      <approvedScriptHashes/>
      <approvedSignatures>
{{- range $key, $val := .Values.Master.ScriptApproval }}
        <string>{{ $val }}</string>
{{- end }}
      </approvedSignatures>
      <aclApprovedSignatures/>
      <approvedClasspathEntries/>
      <pendingScripts/>
      <pendingSignatures/>
      <pendingClasspathEntries/>
    </scriptApproval>
{{- end }}
  jenkins.CLI.xml: |-
    <?xml version='1.1' encoding='UTF-8'?>
    <jenkins.CLI>
{{- if .Values.Master.CLI }}
      <enabled>true</enabled>
{{- else }}
      <enabled>false</enabled>
{{- end }}
    </jenkins.CLI>
  apply_config.sh: |-
    mkdir -p /usr/share/jenkins/ref/secrets/;
    echo "false" > /usr/share/jenkins/ref/secrets/slave-to-master-security-kill-switch;
    cp -n /var/jenkins_config/config.xml /var/jenkins_home;
    cp -n /var/jenkins_config/jenkins.CLI.xml /var/jenkins_home;
{{- if .Values.Master.InstallPlugins }}
    # Install missing plugins
    cp /var/jenkins_config/plugins.txt /var/jenkins_home;
    rm -rf /usr/share/jenkins/ref/plugins/*.lock
    /usr/local/bin/install-plugins.sh `echo $(cat /var/jenkins_home/plugins.txt)`;
    # Copy plugins to shared volume
    cp -n /usr/share/jenkins/ref/plugins/* /var/jenkins_plugins;
{{- end }}
{{- if .Values.Master.ScriptApproval }}
    cp -n /var/jenkins_config/scriptapproval.xml /var/jenkins_home/scriptApproval.xml;
{{- end }}
{{- if .Values.Master.InitScripts }}
    mkdir -p /var/jenkins_home/init.groovy.d/;
    cp -n /var/jenkins_config/*.groovy /var/jenkins_home/init.groovy.d/
{{- end }}
{{- if .Values.Master.CredentialsXmlSecret }}
    cp -n /var/jenkins_credentials/credentials.xml /var/jenkins_home;
{{- end }}
{{- if .Values.Master.SecretsFilesSecret }}
    cp -n /var/jenkins_secrets/* /usr/share/jenkins/ref/secrets;
{{- end }}
{{- if .Values.Master.Jobs }}
    for job in $(ls /var/jenkins_jobs); do
      mkdir -p /var/jenkins_home/jobs/$job
      cp -n /var/jenkins_jobs/$job /var/jenkins_home/jobs/$job/config.xml
    done
{{- end }}
{{- range $key, $val := .Values.Master.InitScripts }}
  init{{ $key }}.groovy: |-
{{ $val | indent 4 }}
{{- end }}
  plugins.txt: |-
{{- if .Values.Master.InstallPlugins }}
{{- range $index, $val := .Values.Master.InstallPlugins }}
{{ $val | indent 4 }}
{{- end }}
{{- end }}
{{- end }}