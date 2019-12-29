#!/usr/bin/env python
# -*- coding: utf-8 -*-


class Foo:
    class Bar:
        BAR = 12

        class Baz:
            pass

        class Qux:
            class Bar:
                BAR = 12

                class Baz:
                    pass

                class Qux:
                    pass

            pass

    class Bar1:
        BAR = 12

        class Baz:
            pass

        class Qux:
            class Bar:
                BAR = 12

                class Baz:
                    pass

                class Qux:
                    pass

        pass

    class Bar2:
        BAR = 12

        class Baz:
            pass

        class Qux:
            class Bar:
                BAR = 12

                class Baz:
                    pass

                class Qux:
                    pass

        pass

    def qux(self):
        def thing1():
            pass

        if True:

            def thing2():
                pass
        else:

            def thing3():
                pass

        def thing4():
            pass

    def qux1(self):
        def thing1():
            pass

        if True:

            def thing2():
                pass
        else:

            def thing3():
                pass

        def thing4():
            pass
