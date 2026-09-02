const std = @import("std");

pub const CatalogVersion = "1.0.0-stage01";

pub const Entry = struct {
    canonical_index: u8,
    text: []const u8,
};

pub const cutlets = [_]Entry{
    .{ .canonical_index = 1, .text = "Қола" },
    .{ .canonical_index = 2, .text = "Түлкі" },
    .{ .canonical_index = 3, .text = "Бүйрек" },
    .{ .canonical_index = 4, .text = "Лагаш" },
    .{ .canonical_index = 5, .text = "Ой" },
    .{ .canonical_index = 6, .text = "Тоғыздың төрт бөлігі" },
    .{ .canonical_index = 7, .text = "Палгураш" },
    .{ .canonical_index = 8, .text = "Қоға" },
    .{ .canonical_index = 9, .text = "Шоқ" },
    .{ .canonical_index = 10, .text = "Сарышаян" },
    .{ .canonical_index = 11, .text = "Күл" },
    .{ .canonical_index = 12, .text = "Бидай" },
    .{ .canonical_index = 13, .text = "Өзен" },
    .{ .canonical_index = 14, .text = "Күлкі" },
    .{ .canonical_index = 15, .text = "Аккад" },
    .{ .canonical_index = 16, .text = "Мүйіз" },
    .{ .canonical_index = 17, .text = "Бос құмыра" },
};

pub const months = [_]Entry{
    .{ .canonical_index = 1, .text = "Балшық" },
    .{ .canonical_index = 2, .text = "Анар" },
    .{ .canonical_index = 3, .text = "Шынтақ" },
    .{ .canonical_index = 4, .text = "Қызғаныш" },
    .{ .canonical_index = 5, .text = "Эриду" },
    .{ .canonical_index = 6, .text = "Тіс пастасы" },
    .{ .canonical_index = 7, .text = "Бестің үш бөлігі" },
    .{ .canonical_index = 8, .text = "Қаршумаб" },
    .{ .canonical_index = 9, .text = "Жолбарыс" },
    .{ .canonical_index = 10, .text = "Қалайы" },
    .{ .canonical_index = 11, .text = "Тұман" },
    .{ .canonical_index = 12, .text = "Ладан" },
    .{ .canonical_index = 13, .text = "Ұршық" },
    .{ .canonical_index = 14, .text = "Қабырға" },
    .{ .canonical_index = 15, .text = "Кэроб" },
    .{ .canonical_index = 16, .text = "Урук" },
    .{ .canonical_index = 17, .text = "Ұят" },
    .{ .canonical_index = 18, .text = "Түйе" },
    .{ .canonical_index = 19, .text = "Мыс" },
    .{ .canonical_index = 20, .text = "Құдық" },
    .{ .canonical_index = 21, .text = "Жұмыртқаның сарыуызы" },
    .{ .canonical_index = 22, .text = "Жұлдыз" },
    .{ .canonical_index = 23, .text = "Бал" },
    .{ .canonical_index = 24, .text = "Көкбауыр" },
    .{ .canonical_index = 25, .text = "Әктас" },
    .{ .canonical_index = 26, .text = "Қуаныш" },
    .{ .canonical_index = 27, .text = "Інжір" },
    .{ .canonical_index = 28, .text = "Ниневия" },
    .{ .canonical_index = 29, .text = "Бақа" },
    .{ .canonical_index = 30, .text = "Қарамай" },
    .{ .canonical_index = 31, .text = "Шам" },
    .{ .canonical_index = 32, .text = "Жабық есік" },
    .{ .canonical_index = 33, .text = "Күнжіт" },
    .{ .canonical_index = 34, .text = "Желке" },
    .{ .canonical_index = 35, .text = "Күміс" },
    .{ .canonical_index = 36, .text = "Лалагүл" },
    .{ .canonical_index = 37, .text = "Дауыл" },
    .{ .canonical_index = 38, .text = "Есек" },
    .{ .canonical_index = 39, .text = "Ұн" },
    .{ .canonical_index = 40, .text = "Өкініш" },
    .{ .canonical_index = 41, .text = "Вавилон" },
    .{ .canonical_index = 42, .text = "Тіл" },
    .{ .canonical_index = 43, .text = "Зығыр" },
    .{ .canonical_index = 44, .text = "Тұз" },
    .{ .canonical_index = 45, .text = "Алмұрт" },
    .{ .canonical_index = 46, .text = "Садақ" },
    .{ .canonical_index = 47, .text = "Құм" },
};

pub fn cutletText(index: u8) ![]const u8 {
    if (index < 1 or index > cutlets.len) return error.InvalidCanonicalIndex;
    return cutlets[index - 1].text;
}

pub fn monthText(index: u8) ![]const u8 {
    if (index < 1 or index > months.len) return error.InvalidCanonicalIndex;
    return months[index - 1].text;
}

pub fn validateFrozenCatalog() !void {
    if (cutlets.len != 17) return error.InvalidCatalogLength;
    if (months.len != 47) return error.InvalidCatalogLength;
    for (cutlets, 0..) |entry, i| {
        if (entry.canonical_index != (u8, (i + 1))) return error.InvalidCanonicalIndex;
        if (entry.text.len == 0) return error.EmptyCatalogEntry;
    }
    for (months, 0..) |entry, i| {
        if (entry.canonical_index != (u8, (i + 1))) return error.InvalidCanonicalIndex;
        if (entry.text.len == 0) return error.EmptyCatalogEntry;
    }
}

test "каталог индекстері тұрақты" {
    try validateFrozenCatalog();
    try std.testing.expectEqualStrings("Бидай", try cutletText(12));
    try std.testing.expectEqualStrings("Тұз", try monthText(44));
}
