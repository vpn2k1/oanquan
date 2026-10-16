# WorkManager (kéo vào qua play-services-ads) tạo WorkDatabase_Impl bằng
# reflection; R8 xóa constructor rỗng làm app crash ngay khi mở bản release.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
