// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_settings_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBusinessSettingsSchemaCollection on Isar {
  IsarCollection<BusinessSettingsSchema> get businessSettingsSchemas =>
      this.collection();
}

const BusinessSettingsSchemaSchema = CollectionSchema(
  name: r'BusinessSettingsSchema',
  id: 6734142619915224702,
  properties: {
    r'address': PropertySchema(id: 0, name: r'address', type: IsarType.string),
    r'businessName': PropertySchema(
      id: 1,
      name: r'businessName',
      type: IsarType.string,
    ),
    r'currency': PropertySchema(
      id: 2,
      name: r'currency',
      type: IsarType.string,
    ),
    r'gstin': PropertySchema(id: 3, name: r'gstin', type: IsarType.string),
    r'invoiceFooter': PropertySchema(
      id: 4,
      name: r'invoiceFooter',
      type: IsarType.string,
    ),
    r'invoicePrefix': PropertySchema(
      id: 5,
      name: r'invoicePrefix',
      type: IsarType.string,
    ),
    r'logo': PropertySchema(id: 6, name: r'logo', type: IsarType.string),
    r'phone': PropertySchema(id: 7, name: r'phone', type: IsarType.string),
    r'serverId': PropertySchema(
      id: 8,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'serviceChargePercentage': PropertySchema(
      id: 9,
      name: r'serviceChargePercentage',
      type: IsarType.double,
    ),
    r'syncStatus': PropertySchema(
      id: 10,
      name: r'syncStatus',
      type: IsarType.string,
      enumMap: _BusinessSettingsSchemasyncStatusEnumValueMap,
    ),
    r'taxPercentage': PropertySchema(
      id: 11,
      name: r'taxPercentage',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _businessSettingsSchemaEstimateSize,
  serialize: _businessSettingsSchemaSerialize,
  deserialize: _businessSettingsSchemaDeserialize,
  deserializeProp: _businessSettingsSchemaDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _businessSettingsSchemaGetId,
  getLinks: _businessSettingsSchemaGetLinks,
  attach: _businessSettingsSchemaAttach,
  version: '3.1.0+1',
);

int _businessSettingsSchemaEstimateSize(
  BusinessSettingsSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.address.length * 3;
  bytesCount += 3 + object.businessName.length * 3;
  bytesCount += 3 + object.currency.length * 3;
  bytesCount += 3 + object.gstin.length * 3;
  bytesCount += 3 + object.invoiceFooter.length * 3;
  bytesCount += 3 + object.invoicePrefix.length * 3;
  bytesCount += 3 + object.logo.length * 3;
  bytesCount += 3 + object.phone.length * 3;
  {
    final value = object.serverId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.syncStatus.name.length * 3;
  return bytesCount;
}

void _businessSettingsSchemaSerialize(
  BusinessSettingsSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.businessName);
  writer.writeString(offsets[2], object.currency);
  writer.writeString(offsets[3], object.gstin);
  writer.writeString(offsets[4], object.invoiceFooter);
  writer.writeString(offsets[5], object.invoicePrefix);
  writer.writeString(offsets[6], object.logo);
  writer.writeString(offsets[7], object.phone);
  writer.writeString(offsets[8], object.serverId);
  writer.writeDouble(offsets[9], object.serviceChargePercentage);
  writer.writeString(offsets[10], object.syncStatus.name);
  writer.writeDouble(offsets[11], object.taxPercentage);
  writer.writeDateTime(offsets[12], object.updatedAt);
}

BusinessSettingsSchema _businessSettingsSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BusinessSettingsSchema();
  object.address = reader.readString(offsets[0]);
  object.businessName = reader.readString(offsets[1]);
  object.currency = reader.readString(offsets[2]);
  object.gstin = reader.readString(offsets[3]);
  object.id = id;
  object.invoiceFooter = reader.readString(offsets[4]);
  object.invoicePrefix = reader.readString(offsets[5]);
  object.logo = reader.readString(offsets[6]);
  object.phone = reader.readString(offsets[7]);
  object.serverId = reader.readStringOrNull(offsets[8]);
  object.serviceChargePercentage = reader.readDouble(offsets[9]);
  object.syncStatus =
      _BusinessSettingsSchemasyncStatusValueEnumMap[reader.readStringOrNull(
        offsets[10],
      )] ??
      SyncStatus.pending;
  object.taxPercentage = reader.readDouble(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  return object;
}

P _businessSettingsSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (_BusinessSettingsSchemasyncStatusValueEnumMap[reader
                  .readStringOrNull(offset)] ??
              SyncStatus.pending)
          as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _BusinessSettingsSchemasyncStatusEnumValueMap = {
  r'pending': r'pending',
  r'synced': r'synced',
  r'failed': r'failed',
};
const _BusinessSettingsSchemasyncStatusValueEnumMap = {
  r'pending': SyncStatus.pending,
  r'synced': SyncStatus.synced,
  r'failed': SyncStatus.failed,
};

Id _businessSettingsSchemaGetId(BusinessSettingsSchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _businessSettingsSchemaGetLinks(
  BusinessSettingsSchema object,
) {
  return [];
}

void _businessSettingsSchemaAttach(
  IsarCollection<dynamic> col,
  Id id,
  BusinessSettingsSchema object,
) {
  object.id = id;
}

extension BusinessSettingsSchemaQueryWhereSort
    on QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QWhere> {
  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BusinessSettingsSchemaQueryWhere
    on
        QueryBuilder<
          BusinessSettingsSchema,
          BusinessSettingsSchema,
          QWhereClause
        > {
  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterWhereClause
  >
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BusinessSettingsSchemaQueryFilter
    on
        QueryBuilder<
          BusinessSettingsSchema,
          BusinessSettingsSchema,
          QFilterCondition
        > {
  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'address',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'address',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'businessName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'businessName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'businessName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'businessName', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  businessNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'businessName', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'currency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'currency',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currency', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'currency', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'gstin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gstin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gstin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gstin',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'gstin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'gstin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'gstin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'gstin',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'gstin', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  gstinIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'gstin', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'invoiceFooter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'invoiceFooter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'invoiceFooter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'invoiceFooter',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'invoiceFooter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'invoiceFooter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'invoiceFooter',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'invoiceFooter',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'invoiceFooter', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoiceFooterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'invoiceFooter', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'invoicePrefix',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'invoicePrefix',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'invoicePrefix',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'invoicePrefix',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'invoicePrefix',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'invoicePrefix',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'invoicePrefix',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'invoicePrefix',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'invoicePrefix', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  invoicePrefixIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'invoicePrefix', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'logo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'logo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'logo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'logo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'logo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'logo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'logo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'logo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'logo', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  logoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'logo', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'phone',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'phone',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'phone',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'phone', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  phoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'phone', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverId'),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serverId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serverId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serviceChargePercentageEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serviceChargePercentage',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serviceChargePercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serviceChargePercentage',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serviceChargePercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serviceChargePercentage',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  serviceChargePercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serviceChargePercentage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusEqualTo(SyncStatus value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'syncStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'syncStatus',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  syncStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'syncStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  taxPercentageEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'taxPercentage',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  taxPercentageGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'taxPercentage',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  taxPercentageLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'taxPercentage',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  taxPercentageBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'taxPercentage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    BusinessSettingsSchema,
    BusinessSettingsSchema,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BusinessSettingsSchemaQueryObject
    on
        QueryBuilder<
          BusinessSettingsSchema,
          BusinessSettingsSchema,
          QFilterCondition
        > {}

extension BusinessSettingsSchemaQueryLinks
    on
        QueryBuilder<
          BusinessSettingsSchema,
          BusinessSettingsSchema,
          QFilterCondition
        > {}

extension BusinessSettingsSchemaQuerySortBy
    on QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QSortBy> {
  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByBusinessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByBusinessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByGstin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstin', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByGstinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstin', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByInvoiceFooter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceFooter', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByInvoiceFooterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceFooter', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByInvoicePrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByInvoicePrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByServiceChargePercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceChargePercentage', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByServiceChargePercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceChargePercentage', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BusinessSettingsSchemaQuerySortThenBy
    on
        QueryBuilder<
          BusinessSettingsSchema,
          BusinessSettingsSchema,
          QSortThenBy
        > {
  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByBusinessName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByBusinessNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessName', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByGstin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstin', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByGstinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gstin', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByInvoiceFooter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceFooter', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByInvoiceFooterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceFooter', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByInvoicePrefix() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByInvoicePrefixDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoicePrefix', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByLogo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByLogoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logo', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByServiceChargePercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceChargePercentage', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByServiceChargePercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceChargePercentage', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByTaxPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxPercentage', Sort.desc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension BusinessSettingsSchemaQueryWhereDistinct
    on QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct> {
  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByBusinessName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'businessName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByCurrency({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByGstin({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gstin', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByInvoiceFooter({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'invoiceFooter',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByInvoicePrefix({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'invoicePrefix',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByLogo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByPhone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByServiceChargePercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serviceChargePercentage');
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctBySyncStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByTaxPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxPercentage');
    });
  }

  QueryBuilder<BusinessSettingsSchema, BusinessSettingsSchema, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension BusinessSettingsSchemaQueryProperty
    on
        QueryBuilder<
          BusinessSettingsSchema,
          BusinessSettingsSchema,
          QQueryProperty
        > {
  QueryBuilder<BusinessSettingsSchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  businessNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'businessName');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  gstinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gstin');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  invoiceFooterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceFooter');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  invoicePrefixProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoicePrefix');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  logoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logo');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String, QQueryOperations>
  phoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phone');
    });
  }

  QueryBuilder<BusinessSettingsSchema, String?, QQueryOperations>
  serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<BusinessSettingsSchema, double, QQueryOperations>
  serviceChargePercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serviceChargePercentage');
    });
  }

  QueryBuilder<BusinessSettingsSchema, SyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<BusinessSettingsSchema, double, QQueryOperations>
  taxPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxPercentage');
    });
  }

  QueryBuilder<BusinessSettingsSchema, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
