allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ---------------------------------------------------------------------------
// إضافات Flutter — ومنها flutter_facebook_auth 7.2.0 — تُعلن في ملف
// android/build.gradle الخاص بها كتلة buildscript قديمة الطراز تحدّد إصدار
// AGP بنفسها:
//
//     classpath 'com.android.tools.build:gradle:8.13.0'
//
// وGradle يلتزم بذلك الرقم حرفياً لمشروع الإضافة الفرعي، ولا يستبدله بأقرب
// نسخة مخزّنة محلياً. فإن لم تكن تلك النسخة في ذاكرة Gradle حاول تنزيلها من
// dl.google.com، وإن تعذّر الاتصال فشل البناء كله بـ:
//     Could not resolve com.android.tools.build:gradle:8.13.0
//
// نُثبّت هنا إصدار AGP على نسخة المشروع نفسها (8.11.1) لكل المشاريع الفرعية،
// فيُخدَم طلب الإضافة من الذاكرة المحلية بلا تنزيل، ويبقى إصدار AGP واحد
// متسقاً في البناء كله. والإضافات لا تحتاج AGP إلا لتطبيق com.android.library،
// و8.11.1 يكفيها تماماً (تعرّف namespace وcompileSdk 36).
// ---------------------------------------------------------------------------
subprojects {
    buildscript {
        configurations.all {
            resolutionStrategy.force("com.android.tools.build:gradle:8.11.1")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
