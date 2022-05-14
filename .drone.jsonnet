local checks = {
  kind: "pipeline",
  type: "docker",
  name: "check",
  steps: [
    {
      name: "check",
      image: "rust",
      commands: [
        "cargo check",
      ],
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    },
    {
      name: "build-cache",
      image: "meltwater/drone-cache:dev",
      pull: true,
      environment: {
        "AWS_ACCESS_KEY_ID": {
          from_secret: "s3_access_key"
        },
        "AWS_SECRET_ACCESS_KEY": {
          from_secret: "s3_secret_key"
        },
        "S3_ENDPOINT": {
          from_secret: "s3_server"
        },
        "S3_BUCKET": "rust-rsa",
        "S3_REGION": "us-1",
        "PLUGIN_PATH_STYLE": "true"
      },
      settings: {
        rebuild: true,
        mount: ['/usr/local/cargo']
      },
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    }
  ],
  volumes: [
    {
      name: "cargo",
      temp: {}
    }
  ]
};

local install_cross = {
  kind: "pipeline",
  type: "docker",
  name: "install_cross",
  when: {
    event: [
      "tag"
    ]
  },
  depends_on: [
    "check"
  ],
  steps: [
    {
      name: "restore-cache",
      image: "meltwater/drone-cache:dev",
      pull: true,
      environment: {
        "AWS_ACCESS_KEY_ID": {
          from_secret: "s3_access_key"
        },
        "AWS_SECRET_ACCESS_KEY": {
          from_secret: "s3_secret_key"
        },
        "S3_ENDPOINT": {
          from_secret: "s3_server"
        },
        "S3_BUCKET": "rust-rsa",
        "S3_REGION": "us-1",
        "PLUGIN_PATH_STYLE": "true"
      },
      settings: {
        restore: true,
        mount: ['/usr/local/cargo']
      },
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    },
    {
      name: "install_cross",
      image: "rust",
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo",
        }
      ],
      commands: [
        "cargo install cross"
      ]
    },
    {
      name: "build-cache",
      image: "meltwater/drone-cache:dev",
      pull: true,
      environment: {
        "AWS_ACCESS_KEY_ID": {
          from_secret: "s3_access_key"
        },
        "AWS_SECRET_ACCESS_KEY": {
          from_secret: "s3_secret_key"
        },
        "S3_ENDPOINT": {
          from_secret: "s3_server"
        },
        "S3_BUCKET": "rust-rsa",
        "S3_REGION": "us-1",
        "PLUGIN_PATH_STYLE": "true"
      },
      settings: {
        rebuild: true,
        mount: ['/usr/local/cargo']
      },
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    }
  ],
  volumes: [
    {
      name: "cargo",
      temp: {}
    }
  ]
};

local build(arch) = {
  kind: "pipeline",
  type: "docker",
  name: "rust-stable-" + arch,
  depends_on: [
    "install_cross"
  ],
  when: {
    event: [
      "tag"
    ]
  },
  steps: [
    {
      name: "restore-cache",
      image: "meltwater/drone-cache:dev",
      pull: true,
      environment: {
        "AWS_ACCESS_KEY_ID": {
          from_secret: "s3_access_key"
        },
        "AWS_SECRET_ACCESS_KEY": {
          from_secret: "s3_secret_key"
        },
        "S3_ENDPOINT": {
          from_secret: "s3_server"
        },
        "S3_BUCKET": "rust-rsa",
        "S3_REGION": "us-1",
        "PLUGIN_PATH_STYLE": "true"
      },
      settings: {
        restore: true,
        mount: ['/usr/local/cargo']
      },
      volumes: [
        {
          name: "cargo",
          path: "/usr/local/cargo"
        }
      ]
    },
    {
      name: "build",
      image: "rust",
      volumes: [
        {
          name: "dockersock",
          path: "/var/run/docker.sock",
          readonly: true
        },
        {
          name: "cargo",
          path: "/usr/local/cargo"
        },
        {
          name: "target",
          path: "/target",
        }
      ],
      environment: {
        "CROSS_DOCKER_IN_DOCKER": true,
      },
      commands: [
        "curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz | tar zxvf - --strip 1 -C /usr/bin docker/docker",
        "cross build --release --target " + arch,
        "tar -czvf /target/rust_rsa-" + arch + ".tar.gz -C target/" + arch + "/release ."
      ],
    },
    {
      name: "publish",
      image: "plugins/github-release",
      volumes: [
        {
          name: "target",
          path: "/target",
        }
      ],
      settings: {
        "api_key": { from_secret: "github_token" },
        "files": "/target/rust_rsa-" + arch + ".tar.gz"
      },
    }
  ],
  volumes: [
    {
      name: "dockersock",
      host: {
        path: "/var/run/docker.sock"
      }
    },
    {
      name: "target",
      temp: {}
    },
    {
      name: "cargo",
      temp: {}
    }
  ]
};

[
  checks,
  install_cross,
  build("aarch64-unknown-linux-gnu"),
  build("aarch64-unknown-linux-musl"),
  build("arm-unknown-linux-gnueabi"),
  build("arm-unknown-linux-gnueabihf"),
  build("arm-unknown-linux-musleabi"),
  build("arm-unknown-linux-musleabihf"),
  build("armv5te-unknown-linux-gnueabi"),
  build("armv5te-unknown-linux-musleabi"),
  build("armv7-unknown-linux-gnueabihf"),
  build("armv7-unknown-linux-musleabihf"),
  build("i586-unknown-linux-gnu"),
  build("i586-unknown-linux-musl"),
  build("i686-unknown-freebsd"),
  build("i686-pc-windows-gnu"),
  build("i686-unknown-linux-gnu"),
  build("i686-unknown-linux-musl"),
  build("mips-unknown-linux-gnu"),
  build("mips-unknown-linux-musl"),
  build("mips64-unknown-linux-gnuabi64"),
  build("mips64el-unknown-linux-gnuabi64"),
  build("mipsel-unknown-linux-gnu"),
  build("mipsel-unknown-linux-musl"),
  build("powerpc-unknown-linux-gnu"),
  build("powerpc64-unknown-linux-gnu"),
  build("powerpc64le-unknown-linux-gnu"),
  build("riscv64gc-unknown-linux-gnu"),
  build("s390x-unknown-linux-gnu"),
  build("sparc64-unknown-linux-gnu"),
  build("sparcv9-sun-solaris"),
  build("thumbv6m-none-eabi"),
  build("thumbv7em-none-eabi"),
  build("thumbv7em-none-eabihf"),
  build("thumbv7m-none-eabi"),
  build("x86_64-pc-windows-gnu"),
  build("x86_64-sun-solaris"),
  build("x86_64-unknown-freebsd"),
  build("x86_64-unknown-linux-gnu"),
  build("x86_64-unknown-linux-musl"),
  build("x86_64-unknown-netbsd")
]
