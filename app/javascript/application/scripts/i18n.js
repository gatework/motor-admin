// 国际化文案表：集中维护后台设置页的英文和简体中文界面文本。
const FALLBACK_LOCALE = 'en'

const MESSAGES = {
  en: {
    settings: {
      header: {
        settings: 'Settings',
        adminPanel: 'Admin Panel',
        motorAdmin: 'Motor Admin'
      },
      common: {
        proFeatureTitle: 'This feature is available in Motor Admin Pro',
        proFeatureAction: 'Learn More',
        select: 'Select',
        notFound: 'Not Found',
        createNew: 'Create New',
        loading: 'Loading',
        ok: 'OK',
        submit: 'Submit'
      },
      tabs: {
        general: 'General',
        users: 'Users',
        roles: 'Roles',
        database: 'Database',
        email: 'Email',
        storage: 'Storage',
        other: 'Other'
      },
      languageSelectLabel: 'Language',
      languageOptions: {
        en: 'English',
        es: 'Español',
        el: 'Ελληνικά',
        'zh-CN': '简体中文'
      },
      otherPage: {
        slackToken: 'Slack Token',
        slackTokenPlaceholder: 'API Token',
        createSlackBotHere: 'Create a Slack Bot here',
        submit: 'Submit',
        trackingScript: 'Tracking script',
        trackingScriptPlaceholder: '<script> </script>',
        languageChanged: 'Admin panel language has been changed!',
        changesSaved: 'Changes have been saved!',
        credentialsSaved: 'Credentials have been saved!',
        proFeatureTitle: 'This feature is available in Motor Admin Pro',
        proFeatureAction: 'Learn More'
      },
      generalPage: {
        submitUpdate: 'Update',
        submitSubscribe: 'Subscribe',
        signOut: 'Sign Out',
        userUpdated: 'User has been updated successfully',
        subscribed: 'You have been subscribed successfully'
      },
      emailPage: {
        hostLabel: 'Host',
        hostPlaceholder: 'smtp.example.com',
        portLabel: 'Port',
        portPlaceholder: '587',
        usernameLabel: 'Username',
        usernamePlaceholder: 'admin',
        passwordLabel: 'Password',
        passwordPlaceholder: '**********',
        addressLabel: 'Send from',
        addressPlaceholder: 'user@example.com',
        updatedSuccess: 'Email settings have been updated successfully',
        submitUpdate: 'Update'
      },
      databasePage: {
        expand: 'Expand',
        remove: 'Remove',
        addDatabase: 'Add Database',
        createDatabase: 'Add Database',
        nameLabel: 'Name',
        namePlaceholder: 'Database name',
        areYouSure: 'Are you sure?',
        removed: 'Database credentials have been removed',
        updatedSuccess: 'Database credentials have been updated successfully',
        submitUpdate: 'Update',
        submitCreate: 'Add Database',
        urlLabel: 'URL',
        urlPlaceholder: 'postgresql://username:password@localhost:5432/db_name',
        hostLabel: 'Host',
        hostPlaceholder: 'example.com',
        portLabel: 'Port',
        portPlaceholder: '5432',
        usernameLabel: 'Username',
        usernamePlaceholder: 'admin',
        passwordLabel: 'Password',
        passwordPlaceholder: '**********',
        databaseLabel: 'Database',
        databasePlaceholder: 'db_name',
        schemaLabel: 'Schemas',
        schemaPlaceholder: 'public, custom_schema',
        dbTypePostgreSQL: 'PostgreSQL',
        dbTypeMySQL: 'MySQL',
        dbTypeSqlServer: 'SQL Server',
        dockerHostHint: 'Use <code>`host.docker.internal`</code> on macOS and Windows.'
      },
      storagePage: {
        labelAws: 'S3',
        labelGoogleCloud: 'Google Cloud',
        updatedSuccess: 'File storage settings have been updated successfully',
        awsAccessKeyIdLabel: 'Access key ID',
        awsAccessKeyIdPlaceholder: 'AKIA...',
        awsSecretAccessKeyLabel: 'Secret access key',
        awsSecretAccessKeyPlaceholder: '**********',
        awsRegionLabel: 'Region',
        awsRegionPlaceholder: 'us-east-1',
        awsBucketLabel: 'Bucket',
        awsBucketPlaceholder: 's3-bucket-name',
        awsEndpointLabel: 'Endpoint',
        awsEndpointPlaceholder: '',
        awsEndpointHint: 'Use a custom endpoint for S3-compatible APIs like MinIO. Leave it blank for AWS S3.',
        gcsProjectLabel: 'Project',
        gcsProjectPlaceholder: 'my-project',
        gcsBucketLabel: 'Bucket',
        gcsBucketPlaceholder: 'my-bucket',
        gcsCredentialsLabel: 'Credentials (JSON key content)',
        updateSubmit: 'Update'
      },
      rolesPage: {
        addRole: 'Add Role',
        createNewRole: 'Create New Role',
        addRoleSubmit: 'Add Role',
        added: '{name} role has been added',
        editTitle: 'Edit Role: {name}',
        remove: 'Remove',
        areYouSure: 'Are you sure?',
        nameLabel: 'Name',
        namePlaceholder: 'Role Name',
        permissionsLabel: 'Permissions',
        addRule: 'Add',
        submitButton: 'OK',
        updateSubmit: 'Update'
      },
      rulesPage: {
        filterLabel: 'Filters',
        permittedTagsLabel: 'Permitted tags',
        permittedFieldsLabel: 'Permitted fields',
        addFilter: 'Add Filter',
        authorIdLabel: 'Author ID',
        selectFieldPlaceholder: 'Select Field',
        valuesPlaceholder: 'Values',
        userId: 'User ID',
        userEmail: 'User email',
        subjectSelectPlaceholder: 'Select Resource',
        subjectSelectAll: 'All',
        subjectSelectForms: 'Forms',
        subjectSelectQueries: 'Queries',
        subjectSelectDashboards: 'Dashboards',
        subjectSelectAlerts: 'Alerts',
        subjectSelectNotes: 'Notes',
        tagsPlaceholder: 'Select tags',
        actionsPlaceholder: 'Select Actions',
        actionManage: 'Manage',
        actionRead: 'Read',
        actionCreate: 'Create',
        actionUpdate: 'Edit',
        actionDestroy: 'Remove'
      },
      usersPage: {
        addUser: 'Add User',
        addUserSubmit: 'Add User',
        updateSubmit: 'Update',
        added: '{email} user has been added',
        updated: '{email} user has been updated',
        resetPasswordSent: 'Reset password instructions have been sent to {email}',
        removed: '{email} user has been removed',
        edit: 'Edit',
        resetPassword: 'Reset password',
        remove: 'Remove',
        areYouSure: 'Are you sure?',
        firstNameLabel: 'First Name',
        firstNamePlaceholder: 'John',
        lastNameLabel: 'Last Name',
        lastNamePlaceholder: 'Doe',
        emailLabel: 'Email',
        emailPlaceholder: 'example@example.com',
        passwordLabel: 'Password',
        passwordPlaceholder: '**********',
        rolesLabel: 'Roles',
        rolesPlaceholder: 'Select Roles'
      },
      setupPage: {
        pageTitle: 'Motor Admin Setup 👋',
        start: "Let's go!",
        connectToDatabase: 'Connect to Database',
        subscribe: 'Subscribe',
        skipStep: 'Skip this step'
      },
      subscribePage: {
        description: 'Subscribe to receive newsletters with feature updates and new version releases',
        emailPlaceholder: 'example@example.com',
        subscribedMessage: 'You have been subscribed for newsletters',
        subscribedMessageWithEmail: '{email} has been subscribed for newsletters',
        submit: 'Submit'
      }
    }
  },
  'zh-CN': {
    settings: {
    header: {
      settings: '设置',
      adminPanel: '管理后台',
      motorAdmin: 'Motor Admin'
    },
    common: {
      proFeatureTitle: '该功能仅在 Motor Admin Pro 中可用',
      proFeatureAction: '了解更多',
      select: '选择',
      notFound: '未找到',
      createNew: '新建',
      loading: '加载中',
      ok: '确定',
      submit: '提交'
    },
    tabs: {
      general: '通用',
      users: '用户',
      roles: '角色',
        database: '数据库',
        email: '邮箱',
        storage: '存储',
        other: '其他'
      },
      languageSelectLabel: '语言',
      languageOptions: {
        en: 'English',
        es: 'Español',
        el: 'Ελληνικά',
        'zh-CN': '简体中文'
      },
      otherPage: {
        slackToken: 'Slack 令牌',
        slackTokenPlaceholder: 'API 密钥',
        createSlackBotHere: '在此创建 Slack Bot',
        submit: '保存',
        trackingScript: '埋点脚本',
        trackingScriptPlaceholder: '<script> </script>',
        languageChanged: '后台语言已更新',
        changesSaved: '已保存更改',
        credentialsSaved: '凭据已保存',
        proFeatureTitle: '该功能仅在 Motor Admin Pro 中可用',
        proFeatureAction: '了解更多'
      },
      generalPage: {
        submitUpdate: '更新',
        submitSubscribe: '订阅',
        signOut: '退出登录',
        userUpdated: '用户资料已更新',
        subscribed: '订阅成功'
      },
      emailPage: {
        hostLabel: '主机',
        hostPlaceholder: 'smtp.example.com',
        portLabel: '端口',
        portPlaceholder: '587',
        usernameLabel: '用户名',
        usernamePlaceholder: 'admin',
        passwordLabel: '密码',
        passwordPlaceholder: '**********',
        addressLabel: '发送自',
        addressPlaceholder: 'user@example.com',
        updatedSuccess: '邮箱设置更新成功',
        submitUpdate: '更新'
      },
      databasePage: {
        expand: '展开',
        remove: '移除',
        addDatabase: '添加数据库',
        createDatabase: '添加数据库',
        nameLabel: '名称',
        namePlaceholder: '数据库名称',
        areYouSure: '确定要继续吗？',
        removed: '数据库凭据已删除',
        updatedSuccess: '数据库凭据更新成功',
        submitUpdate: '更新',
        submitCreate: '添加数据库',
        urlLabel: 'URL',
        urlPlaceholder: 'postgresql://用户名:密码@localhost:5432/db_name',
        hostLabel: '主机',
        hostPlaceholder: 'example.com',
        portLabel: '端口',
        portPlaceholder: '5432',
        usernameLabel: '用户名',
        usernamePlaceholder: 'admin',
        passwordLabel: '密码',
        passwordPlaceholder: '**********',
        databaseLabel: '数据库',
        databasePlaceholder: 'db_name',
        schemaLabel: '模式',
        schemaPlaceholder: 'public, custom_schema',
        dbTypePostgreSQL: 'PostgreSQL',
        dbTypeMySQL: 'MySQL',
        dbTypeSqlServer: 'SQL Server',
        dockerHostHint: '在 macOS 和 Windows 上请使用 <code>`host.docker.internal`</code>.'
      },
      storagePage: {
        labelAws: 'S3',
        labelGoogleCloud: 'Google Cloud',
        updatedSuccess: '文件存储设置已更新',
        awsAccessKeyIdLabel: '访问密钥 ID',
        awsAccessKeyIdPlaceholder: 'AKIA...',
        awsSecretAccessKeyLabel: '密钥',
        awsSecretAccessKeyPlaceholder: '**********',
        awsRegionLabel: '地域',
        awsRegionPlaceholder: 'us-east-1',
        awsBucketLabel: '存储桶',
        awsBucketPlaceholder: 's3-bucket-name',
        awsEndpointLabel: '端点',
        awsEndpointPlaceholder: '',
        awsEndpointHint: '请填写 S3 兼容 API 的自定义端点。若使用 AWS S3，可留空',
        gcsProjectLabel: '项目',
        gcsProjectPlaceholder: 'my-project',
        gcsBucketLabel: '存储桶',
        gcsBucketPlaceholder: 'my-bucket',
        gcsCredentialsLabel: '凭据（JSON）',
        updateSubmit: '更新'
      },
      rolesPage: {
        addRole: '新增角色',
        createNewRole: '创建新角色',
        addRoleSubmit: '新增角色',
        added: '{name} 角色已添加',
        editTitle: '编辑角色: {name}',
        remove: '移除',
        areYouSure: '确定要继续吗？',
        nameLabel: '名称',
        namePlaceholder: '角色名称',
        permissionsLabel: '权限',
        addRule: '添加',
        submitButton: '确定',
        updateSubmit: '更新'
      },
      rulesPage: {
        filterLabel: '过滤条件',
        permittedTagsLabel: '允许标签',
        permittedFieldsLabel: '允许字段',
        addFilter: '添加过滤条件',
        authorIdLabel: '作者 ID',
        selectFieldPlaceholder: '选择字段',
        valuesPlaceholder: '值',
        userId: '用户 ID',
        userEmail: '用户邮箱',
        subjectSelectPlaceholder: '选择资源',
        subjectSelectAll: '全部',
        subjectSelectForms: '表单',
        subjectSelectQueries: '查询',
        subjectSelectDashboards: '仪表板',
        subjectSelectAlerts: '告警',
        subjectSelectNotes: '便笺',
        tagsPlaceholder: '选择标签',
        actionsPlaceholder: '选择操作',
        actionManage: '管理',
        actionRead: '读取',
        actionCreate: '创建',
        actionUpdate: '编辑',
        actionDestroy: '移除'
      },
      usersPage: {
        addUser: '新增用户',
        addUserSubmit: '新增用户',
        updateSubmit: '更新',
        added: '{email} 用户已添加',
        updated: '{email} 用户资料已更新',
        resetPasswordSent: '重置密码说明已发送至 {email}',
        removed: '{email} 用户已删除',
        edit: '编辑',
        resetPassword: '重置密码',
        remove: '移除',
        areYouSure: '确定要继续吗？',
        firstNameLabel: '名',
        firstNamePlaceholder: '张',
        lastNameLabel: '姓',
        lastNamePlaceholder: '三',
        emailLabel: '邮箱',
        emailPlaceholder: 'example@example.com',
        passwordLabel: '密码',
        passwordPlaceholder: '**********',
        rolesLabel: '角色',
        rolesPlaceholder: '选择角色'
      },
      setupPage: {
        pageTitle: 'Motor Admin 安装向导 👋',
        start: '开始',
        connectToDatabase: '连接数据库',
        subscribe: '订阅',
        skipStep: '跳过此步骤'
      },
      subscribePage: {
        description: '订阅功能更新和新版本发布的邮件通知',
        emailPlaceholder: 'example@example.com',
        subscribedMessage: '已订阅邮件通知',
        subscribedMessageWithEmail: '{email} 已订阅邮件通知',
        submit: '提交'
      }
    }
  }
}

// 归一化 locale，支持 zh 简写回退到 zh-CN，未知语言回退英文。
const normalizeLocale = (locale) => {
  if (!locale) {
    return FALLBACK_LOCALE
  }

  const safe = locale.toLowerCase()

  if (safe === 'zh-cn' || safe.startsWith('zh')) {
    return 'zh-CN'
  }

  return safe.startsWith('en') ? 'en' : FALLBACK_LOCALE
}

// 将文案中的 {name} 占位符替换为传入值。
const interpolate = (value, replacements = {}) => {
  if (!value || typeof value !== 'string') {
    return value
  }

  return value.replace(/\{(\w+)\}/g, (match, token) => {
    return Object.prototype.hasOwnProperty.call(replacements, token) ? replacements[token] : match
  })
}

// 按 key 路径读取指定语言文案，缺失时逐级回退到英文和 fallback。
const getMessage = (locale, key, fallback = '', replacements = {}) => {
  const locales = [normalizeLocale(locale), FALLBACK_LOCALE]
  const path = key.split('.')

  for (const keyLocale of locales) {
    const bundle = MESSAGES[keyLocale] || MESSAGES[FALLBACK_LOCALE]

    const value = path.reduce((acc, segment) => (acc && acc[segment] ? acc[segment] : undefined), bundle)

    if (value !== undefined && value !== null) {
      return interpolate(value, replacements)
    }
  }

  return interpolate(fallback, replacements)
}

// 从 DOM html[lang] 读取当前语言。
const localeFromDom = () => document.documentElement.getAttribute('lang') || FALLBACK_LOCALE

export { getMessage, localeFromDom, normalizeLocale }
