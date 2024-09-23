FROM --platform=linux/amd64 ubuntu:20.04

# Lista das versões dos softwares que vão ser instalados
ARG bwa_version=0.7.17
ARG freebayes_version=1.3.6
ARG picard_version=2.27.4
ARG fastqc_version=0.11.9
ARG samtools_version=1.14
ARG snpEff_version=5.0

# Atualizando e instalando pacotes importantes
RUN apt-get update && apt-get install -y \
 wget \
 git 

# Instalando o gerenciador dos pacotes que vão ser instalados
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_23.1.0-1-Linux-x86_64.sh && \
 bash Miniconda3-py39_23.1.0-1-Linux-x86_64.sh -p /miniconda -b  && \
 rm Miniconda3-py39_23.1.0-1-Linux-x86_64.sh

# Definindo o ambiente conda
ENV PATH="/miniconda/bin:$PATH"

# Instalando os programas necessários 
RUN conda install -c conda-forge mamba && \
    mamba install -c bioconda -c conda-forge \
    freebayes=${freebayes_version} \
    picard=${picard_version} \
    bwa=${bwa_version} \
    fastqc=${fastqc_version} \
    samtools=${samtools_version} \
    snpeff=${snpEff_version}


# Criar e definir diretório para trabalhar
WORKDIR /call_variant

# Copiar script e todos os dados utilizados. Importante voce criar um pasta data e colocar os FASTQ, GENOME REF, BED e script
COPY data/* /call_variant/

#Copiar o script 
COPY script/script_vcf.sh /call_variant/

# Dando permissão para ser rodado
RUN chmod +x script_vcf.sh

# Limpando o cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/call_variant/script_vcf.sh"]
