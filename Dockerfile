FROM azul/zulu-openjdk-debian:11.0.11

WORKDIR /opt

ENV HADOOP_HOME=/opt/hadoop-2.10.1
ENV HIVE_HOME=/opt/apache-hive-2.3.9-bin
# Include additional jars
ENV HADOOP_CLASSPATH=/opt/hadoop-2.10.1/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.271.jar:/opt/hadoop-2.10.1/share/hadoop/tools/lib/hadoop-aws-2.10.1.jar

ENV AWS_ACCESS_KEY_ID=accessKey1
ENV AWS_SECRET_ACCESS_KEY=secretKey1
ENV AWS_S3_ENDPOINT=

RUN apt-get update && \
    apt-get -qqy install curl vim procps wget&& \
    curl -L https://www.apache.org/dist/hive/hive-2.3.9/apache-hive-2.3.9-bin.tar.gz | tar zxf - && \
    curl -L https://www.apache.org/dist/hadoop/common/hadoop-2.10.1/hadoop-2.10.1.tar.gz | tar zxf - && \
    apt-get install --only-upgrade openssl libssl1.1 && \
    apt-get install -y libk5crypto3 libkrb5-3 libsqlite3-0

RUN rm ${HIVE_HOME}/lib/postgresql-9.4.1208.jre7.jar

RUN curl -o ${HIVE_HOME}/lib/postgresql-9.4.1212.jre7.jar -L https://jdbc.postgresql.org/download/postgresql-9.4.1212.jre7.jar

# Setup Credentials File
RUN mkdir ~/.aws && \
    echo "[default]" > ~/.aws/credentials && \
    echo  aws_access_key_id=${AWS_ACCESS_KEY_ID} >> ~/.aws/credentials && \
    echo  aws_secret_access_key=${AWS_SECRET_ACCESS_KEY} >> ~/.aws/credentials && \
    echo  >> ~/.aws/credentials

COPY conf ${HIVE_HOME}/conf

#Ideally this should be in an entrypoint.sh script
RUN sed -i 's/AWS_ACCESS_KEY_ID/'"$AWS_ACCESS_KEY_ID"'/g' ${HIVE_HOME}/conf/hive-site.xml
RUN sed -i 's/AWS_SECRET_ACCESS_KEY/'"$AWS_SECRET_ACCESS_KEY"'/g' ${HIVE_HOME}/conf/hive-site.xml
RUN sed -i 's/AWS_S3_ENDPOINT/'"$AWS_S3_ENDPOINT"'/g' ${HIVE_HOME}/conf/hive-site.xml

RUN groupadd -r hive --gid=1000 && \
    useradd -r -g hive --uid=1000 -d ${HIVE_HOME} hive && \
    chown hive:hive -R ${HIVE_HOME}

USER hive
WORKDIR $HIVE_HOME




EXPOSE 9083

ENTRYPOINT ["bin/hive"]
CMD ["--service", "metastore"]
