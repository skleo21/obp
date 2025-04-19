# Multi-stage build for Open Banking Project API
FROM maven:3.8-openjdk-11 AS builder

WORKDIR /app

# Clone the repository
RUN git clone --depth 1 https://github.com/OpenBankProject/OBP-API.git .

# Create necessary property files
RUN cp obp-api/src/main/resources/props/sample.props.template obp-api/src/main/resources/props/production.default.props \
    && echo "connector=star" > obp-api/src/main/resources/props/test.default.props \
    && echo "starConnector_supported_types=mapped,internal" >> obp-api/src/main/resources/props/test.default.props \
    && echo "hostname=http://localhost:8080" >> obp-api/src/main/resources/props/test.default.props \
    && echo "tests.port=8080" >> obp-api/src/main/resources/props/test.default.props \
    && echo "payments_enabled=false" >> obp-api/src/main/resources/props/test.default.props \
    && echo "importer_secret=change_me" >> obp-api/src/main/resources/props/test.default.props \
    && echo "messageQueue.updateBankAccountsTransaction=false" >> obp-api/src/main/resources/props/test.default.props \
    && echo "messageQueue.createBankAccounts=false" >> obp-api/src/main/resources/props/test.default.props \
    && echo "allow_sandbox_account_creation=true" >> obp-api/src/main/resources/props/test.default.props \
    && echo "allow_sandbox_data_import=true" >> obp-api/src/main/resources/props/test.default.props \
    && echo "sandbox_data_import_secret=change_me" >> obp-api/src/main/resources/props/test.default.props \
    && echo "allow_account_deletion=true" >> obp-api/src/main/resources/props/test.default.props \
    && echo "allowed_internal_redirect_urls = /,/oauth/authorize" >> obp-api/src/main/resources/props/test.default.props \
    && echo "transactionRequests_enabled=true" >> obp-api/src/main/resources/props/test.default.props \
    && echo "transactionRequests_supported_types=SEPA,SANDBOX_TAN,FREE_FORM,COUNTERPARTY,ACCOUNT,SIMPLE" >> obp-api/src/main/resources/props/test.default.props \
    && echo "SIMPLE_OTP_INSTRUCTION_TRANSPORT=dummy" >> obp-api/src/main/resources/props/test.default.props \
    && echo "ACCOUNT_OTP_INSTRUCTION_TRANSPORT=dummy" >> obp-api/src/main/resources/props/test.default.props \
    && echo "SEPA_OTP_INSTRUCTION_TRANSPORT=dummy" >> obp-api/src/main/resources/props/test.default.props \
    && echo "FREE_FORM_OTP_INSTRUCTION_TRANSPORT=dummy" >> obp-api/src/main/resources/props/test.default.props \
    && echo "COUNTERPARTY_OTP_INSTRUCTION_TRANSPORT=dummy" >> obp-api/src/main/resources/props/test.default.props \
    && echo "SEPA_CREDIT_TRANSFERS_OTP_INSTRUCTION_TRANSPORT=dummy" >> obp-api/src/main/resources/props/test.default.props \
    && echo "openredirects.hostname.whitlelist=http://127.0.0.1,http://localhost" >> obp-api/src/main/resources/props/test.default.props \
    && echo "remotedata.secret = foobarbaz" >> obp-api/src/main/resources/props/test.default.props \
    && echo "allow_public_views=true" >> obp-api/src/main/resources/props/test.default.props \
    && echo "allow_oauth2_login=true" >> obp-api/src/main/resources/props/test.default.props \
    && echo "oauth2.jwk_set.url=https://www.googleapis.com/oauth2/v3/certs" >> obp-api/src/main/resources/props/test.default.props \
    && echo "ResetPasswordUrlEnabled=true" >> obp-api/src/main/resources/props/test.default.props \
    && echo "consents.allowed=true" >> obp-api/src/main/resources/props/test.default.props

# Build the project
RUN MAVEN_OPTS="-Xmx3G -Xss2m" mvn clean package -Pprod -DskipTests

# Look for the WAR file and ensure it exists
RUN ls -la obp-api/target/
RUN find obp-api/target/ -name "*.war" -type f | grep -q . || exit 1

# Second stage - runtime image
FROM openjdk:11-jre-slim

WORKDIR /opt/obp

# Copy the WAR file from the builder stage
COPY --from=builder /app/obp-api/target/obp-api-*.war /opt/obp/obp-api.war

# Create logs directory with proper permissions
RUN mkdir -p /opt/obp/logs && \
    chmod -R 777 /opt/obp/logs

# Create configuration directory
RUN mkdir -p /opt/obp/conf

# Create default props file
RUN echo "# Default OBP Properties" > /opt/obp/conf/default.props \
    && echo "connector=star" >> /opt/obp/conf/default.props \
    && echo "starConnector_supported_types=mapped,internal" >> /opt/obp/conf/default.props \
    && echo "db.driver=${DB_DRIVER:-org.postgresql.Driver}" >> /opt/obp/conf/default.props \
    && echo "db.url=${DB_URL:-jdbc:postgresql://obp-db:5432/obp_db}" >> /opt/obp/conf/default.props \
    && echo "db.user=${DB_USER:-obp}" >> /opt/obp/conf/default.props \
    && echo "db.password=${DB_PASSWORD:-obpsecurepassword}" >> /opt/obp/conf/default.props \
    && echo "logging.level=${LOGGING_LEVEL:-INFO}" >> /opt/obp/conf/default.props \
    && echo "logging.file=/opt/obp/logs/obp.log" >> /opt/obp/conf/default.props \
    && echo "allow_sandbox_account_creation=true" >> /opt/obp/conf/default.props \
    && echo "allow_public_views=true" >> /opt/obp/conf/default.props

# Expose the application port
EXPOSE 8080

# Run OBP API
CMD ["java", "-Dprops.resource.dir=/opt/obp/conf", "-jar", "obp-api.war"]