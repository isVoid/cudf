# Copyright (c) 2021, NVIDIA CORPORATION.

from libcpp cimport bool
from libcpp.memory cimport unique_ptr, shared_ptr, make_shared
from libcpp.utility cimport move

from cudf._lib.cpp.lists.count_elements cimport (
    count_elements as cpp_count_elements
)
from cudf._lib.cpp.lists.explode cimport (
    explode_outer as cpp_explode_outer
)
from cudf._lib.cpp.lists.sorting cimport (
    sort_lists as cpp_sort_lists
)
from cudf._lib.cpp.lists.lists_column_view cimport lists_column_view
from cudf._lib.cpp.column.column_view cimport column_view
from cudf._lib.cpp.column.column cimport column

from cudf._lib.cpp.table.table cimport table
from cudf._lib.cpp.table.table_view cimport table_view
from cudf._lib.cpp.types cimport size_type, order, null_order

from cudf._lib.column cimport Column
from cudf._lib.table cimport Table

from cudf._lib.types cimport (
    underlying_type_t_null_order, underlying_type_t_order
)
from cudf._lib.types import Order, NullOrder
from cudf.core.dtypes import ListDtype


def count_elements(Column col):

    # shared_ptr required because lists_column_view has no default
    # ctor
    cdef shared_ptr[lists_column_view] list_view = (
        make_shared[lists_column_view](col.view())
    )
    cdef unique_ptr[column] c_result

    with nogil:
        c_result = move(cpp_count_elements(list_view.get()[0]))

    result = Column.from_unique_ptr(move(c_result))
    return result


def explode_outer(Table tbl, int explode_column_idx, bool ignore_index=False):
    cdef table_view c_table_view = (
        tbl.data_view() if ignore_index else tbl.view()
    )
    cdef size_type c_explode_column_idx = explode_column_idx

    cdef unique_ptr[table] c_result

    with nogil:
        c_result = move(cpp_explode_outer(c_table_view, c_explode_column_idx))

    return Table.from_unique_ptr(
        move(c_result),
        column_names=tbl._column_names,
        index_names=None if ignore_index else tbl._index_names
    )


def sort_lists(Column col, object order_enum, object null_order_enum):
    cdef shared_ptr[lists_column_view] list_view = (
        make_shared[lists_column_view](col.view())
    )
    cdef order c_sort_order = <order><underlying_type_t_order>order_enum.value
    cdef null_order c_null_prec = (
        <null_order><underlying_type_t_null_order>null_order_enum.value
    )

    cdef unique_ptr[column] c_result

    with nogil:
        c_result = move(
            cpp_sort_lists(list_view.get()[0], c_sort_order, c_null_prec)
        )

    return Column.from_unique_ptr(move(c_result))
